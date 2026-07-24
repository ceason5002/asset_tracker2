-- schema_002_allow_django_app_writes.sql
-- Run this in SSMS against PoliceAssetTracker.
--
-- schema.sql's row-level security predicate on dbo.Assets only allowed
-- writes from a SQL login matching an Officer's DbUserName, or db_owner.
-- The Django app connects as a single shared service account (django_app),
-- which can never satisfy that, so all app-side inserts/updates were
-- blocked outright. This exempts django_app from the predicate; any
-- per-officer/per-precinct restrictions on what the app *displays* should
-- be enforced in Django application code instead of DB-level RLS, since
-- RLS-by-login doesn't fit a shared-service-account web app.

DROP SECURITY POLICY Security.PrecinctFilter;
GO

ALTER FUNCTION Security.fn_PrecinctAccessPredicate(@PrecinctId INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS AccessResult
WHERE @PrecinctId = (
    SELECT o.PrecinctId
    FROM dbo.Officers o
    WHERE o.DbUserName = USER_NAME()
)
OR USER_NAME() = 'django_app'
OR IS_MEMBER('db_owner') = 1;
GO

CREATE SECURITY POLICY Security.PrecinctFilter
ADD FILTER PREDICATE Security.fn_PrecinctAccessPredicate(PrecinctId) ON dbo.Assets,
ADD BLOCK PREDICATE Security.fn_PrecinctAccessPredicate(PrecinctId) ON dbo.Assets AFTER INSERT
WITH (STATE = ON);
GO
