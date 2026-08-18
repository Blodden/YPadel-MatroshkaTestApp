import base64
import json
import os
import secrets
from datetime import datetime, timezone

import ydb
import ydb.iam


driver = ydb.Driver(
    endpoint=os.environ["YDB_ENDPOINT"],
    database=os.environ["YDB_DATABASE"],
    credentials=ydb.iam.MetadataUrlCredentials(),
)
driver.wait(fail_fast=True, timeout=5)
pool = ydb.SessionPool(driver)


def _create_table(session):
    session.execute_scheme(
        """
        CREATE TABLE IF NOT EXISTS match_state (
            app_id Utf8,
            match_token Utf8,
            installation_id Utf8,
            revision Int64,
            snapshot_json Utf8,
            push_json Utf8,
            updated_at Utf8,
            PRIMARY KEY (app_id, match_token)
        );
        """
    )
    session.execute_scheme(
        """
        CREATE TABLE IF NOT EXISTS feature_flags (
            app_id Utf8,
            flag_key Utf8,
            enabled Bool,
            revision Int64,
            updated_at Utf8,
            PRIMARY KEY (app_id, flag_key)
        );
        """
    )


pool.retry_operation_sync(_create_table)


def handler(event, context):
    try:
        if event.get("action") == "setFeatureFlag":
            return _set_feature_flag(event)
        if event.get("httpMethod") == "GET":
            return _json_response(200, _feature_config(event.get("queryStringParameters") or {}))
        request = _request_body(event)
        response = _sync(request)
        return _json_response(200, response)
    except (TypeError, ValueError, json.JSONDecodeError) as error:
        return _json_response(400, {"error": str(error) or "invalid_request"})
    except Exception as error:
        detail = f"{type(error).__name__}: {error}"
        print(f"request_failed request_id={context.request_id} error={detail}")
        return _json_response(500, {"error": "server_error"})


def _feature_config(query):
    app_id = _required_string(query, "appId", 128)
    stored = _read_feature_flags(app_id)
    flag = stored.get("cloudSyncEnabled")
    return {
        "revision": flag["revision"] if flag else 0,
        "refreshAfterSeconds": 3600,
        "flags": {"cloudSyncEnabled": flag["enabled"] if flag else True},
    }


def _set_feature_flag(event):
    app_id = _required_string(event, "appId", 128)
    key = _required_string(event, "key", 64)
    enabled = event.get("enabled")
    if key != "cloudSyncEnabled":
        raise ValueError("feature_flag_unknown")
    if not isinstance(enabled, bool):
        raise ValueError("feature_flag_enabled_required")

    current = _read_feature_flags(app_id).get(key)
    revision = current["revision"] if current else 1
    _write_feature_flag(app_id, key, enabled, revision)
    return _feature_config({"appId": app_id})


def _request_body(event):
    body = event.get("body", "{}")
    if event.get("isBase64Encoded") is True:
        body = base64.b64decode(body).decode("utf-8")
    if isinstance(body, str):
        body = json.loads(body)
    if not isinstance(body, dict):
        raise ValueError("object_body_required")
    return body


def _sync(body):
    app_id = _required_string(body, "appId", 128)
    installation_id = _required_string(body, "installationId", 128)
    client_revision = body.get("clientRevision")
    snapshot = body.get("snapshot")
    push = body.get("push") or {}

    if isinstance(client_revision, bool) or not isinstance(client_revision, int) or client_revision < 0:
        raise ValueError("client_revision_required")
    if not isinstance(snapshot, dict):
        raise ValueError("snapshot_required")
    if not isinstance(push, dict):
        raise ValueError("push_invalid")

    snapshot_json = _compact_json(snapshot, 16384, "snapshot_too_large")
    push_json = _compact_json(push, 4096, "push_too_large")
    token = body.get("matchToken")
    if token is not None and (not isinstance(token, str) or len(token) > 128):
        raise ValueError("match_token_invalid")

    current = _read(app_id, token) if token else None
    if current is None:
        token = secrets.token_urlsafe(18)

    if current is None or client_revision >= current["revision"]:
        updated_at = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
        _write(
            app_id,
            token,
            installation_id,
            client_revision,
            snapshot_json,
            push_json,
            updated_at,
        )
        current = {
            "revision": client_revision,
            "snapshot": snapshot,
            "push": push,
            "updatedAt": updated_at,
        }
        status = "updated"
    else:
        status = "current"

    push_token = current["push"].get("token")
    push_enabled = current["push"].get("enabled") is True
    return {
        "status": status,
        "matchToken": token,
        "serverRevision": current["revision"],
        "snapshot": current["snapshot"],
        "pushStatus": "pending_credentials" if push_token and push_enabled else "not_registered",
        "serverTime": current["updatedAt"],
    }


def _read(app_id, token):
    def operation(session):
        query = session.prepare(
            """
            DECLARE $app_id AS Utf8;
            DECLARE $match_token AS Utf8;

            SELECT revision, snapshot_json, push_json, updated_at
            FROM match_state
            WHERE app_id = $app_id AND match_token = $match_token;
            """
        )
        return session.transaction().execute(
            query,
            {"$app_id": app_id, "$match_token": token},
            commit_tx=True,
        )

    result = pool.retry_operation_sync(operation)
    if not result or not result[0].rows:
        return None
    row = result[0].rows[0]
    return {
        "revision": row.revision,
        "snapshot": json.loads(row.snapshot_json),
        "push": json.loads(row.push_json),
        "updatedAt": row.updated_at,
    }


def _write(app_id, token, installation_id, revision, snapshot_json, push_json, updated_at):
    def operation(session):
        query = session.prepare(
            """
            DECLARE $app_id AS Utf8;
            DECLARE $match_token AS Utf8;
            DECLARE $installation_id AS Utf8;
            DECLARE $revision AS Int64;
            DECLARE $snapshot_json AS Utf8;
            DECLARE $push_json AS Utf8;
            DECLARE $updated_at AS Utf8;

            UPSERT INTO match_state (
                app_id, match_token, installation_id, revision,
                snapshot_json, push_json, updated_at
            ) VALUES (
                $app_id, $match_token, $installation_id, $revision,
                $snapshot_json, $push_json, $updated_at
            );
            """
        )
        session.transaction().execute(
            query,
            {
                "$app_id": app_id,
                "$match_token": token,
                "$installation_id": installation_id,
                "$revision": revision,
                "$snapshot_json": snapshot_json,
                "$push_json": push_json,
                "$updated_at": updated_at,
            },
            commit_tx=True,
        )

    pool.retry_operation_sync(operation)


def _read_feature_flags(app_id):
    def operation(session):
        query = session.prepare(
            """
            DECLARE $app_id AS Utf8;

            SELECT flag_key, enabled, revision
            FROM feature_flags
            WHERE app_id = $app_id;
            """
        )
        return session.transaction().execute(
            query,
            {"$app_id": app_id},
            commit_tx=True,
        )

    result = pool.retry_operation_sync(operation)
    if not result:
        return {}
    return {
        row.flag_key: {"enabled": row.enabled, "revision": row.revision}
        for row in result[0].rows
    }


def _write_feature_flag(app_id, key, enabled, revision):
    updated_at = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

    def operation(session):
        query = session.prepare(
            """
            DECLARE $app_id AS Utf8;
            DECLARE $flag_key AS Utf8;
            DECLARE $enabled AS Bool;
            DECLARE $revision AS Int64;
            DECLARE $updated_at AS Utf8;

            UPSERT INTO feature_flags (
                app_id, flag_key, enabled, revision, updated_at
            ) VALUES (
                $app_id, $flag_key, $enabled, $revision, $updated_at
            );
            """
        )
        session.transaction().execute(
            query,
            {
                "$app_id": app_id,
                "$flag_key": key,
                "$enabled": enabled,
                "$revision": revision,
                "$updated_at": updated_at,
            },
            commit_tx=True,
        )

    pool.retry_operation_sync(operation)


def _required_string(body, key, maximum_length):
    value = body.get(key)
    if not isinstance(value, str) or not value or len(value) > maximum_length:
        raise ValueError(f"{key}_required")
    return value


def _compact_json(value, maximum_bytes, error):
    encoded = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    if len(encoded.encode("utf-8")) > maximum_bytes:
        raise ValueError(error)
    return encoded


def _json_response(status, body):
    return {
        "statusCode": status,
        "headers": {
            "Content-Type": "application/json; charset=utf-8",
            "Cache-Control": "no-store",
        },
        "body": json.dumps(body, ensure_ascii=False, separators=(",", ":")),
    }
