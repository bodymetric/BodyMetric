# Quickstart: Authenticated API Request Handling

**Feature**: `010-api-auth-session`  
**Date**: 2026-04-28

---

## What This Feature Changes

Two targeted fixes to the existing auth infrastructure. No new files, no new dependencies.

---

## Fix 1: TokenRefreshService — request body field name

**File**: `BodyMetric/Services/Token/TokenRefreshService.swift`  
**Line**: The `JSONEncoder().encode(["refresh_token": refreshToken])` call

**Before (broken)**:
```swift
request.httpBody = try JSONEncoder().encode(["refresh_token": refreshToken])
```

**After (correct)**:
```swift
request.httpBody = try JSONEncoder().encode(["refreshToken": refreshToken])
```

**Why**: The API expects `refreshToken` (camelCase). The snake_case key `refresh_token` is silently ignored by the server, causing every refresh attempt to fail with a 401.

---

## Fix 2: NetworkClient — URL-path exemption

**File**: `BodyMetric/Services/Network/NetworkClient.swift`  
**Change**: Add private path check; skip token injection for exempt paths

```swift
// Add private helper:
private static let exemptPathPrefixes = ["/api/auth/", "/q/", "/version"]

private func isExemptPath(_ request: URLRequest) -> Bool {
    guard let path = request.url?.path else { return false }
    return Self.exemptPathPrefixes.contains { path.hasPrefix($0) }
}

// Modify data(for:):
func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
    // Exempt paths: skip token injection and send directly
    if isExemptPath(request) {
        return try await executeUnauthenticated(request)
    }

    guard let token = await tokenStore.accessToken else {
        Logger.warning("NetworkClient: no access token — request blocked", category: .network)
        throw NetworkError.noToken
    }
    // ... existing logic unchanged
}

// Add private helper for unauthenticated execution:
private func executeUnauthenticated(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else {
        throw NetworkError.httpError(-1)
    }
    return (data, http)
}
```

---

## Testing Guide

### TokenRefreshServiceTests — add/update

```swift
// Verify the request body uses camelCase key
func test_refresh_sendsCorrectBodyKey() async throws {
    // Set up mock session to capture the request
    // Assert request body JSON has key "refreshToken" (not "refresh_token")
    let body = try XCTUnwrap(capturedRequest.httpBody)
    let dict = try JSONDecoder().decode([String: String].self, from: body)
    XCTAssertNotNil(dict["refreshToken"], "Body must use camelCase key 'refreshToken'")
    XCTAssertNil(dict["refresh_token"], "Body must NOT use snake_case key 'refresh_token'")
}
```

### NetworkClientTests — add

```swift
// Verify /q/* path receives no Authorization header
func test_data_exemptQPath_doesNotAddBearerToken() async throws {
    let request = URLRequest(url: URL(string: "https://api.bodymetric.com.br/q/exercises")!)
    MockURLProtocol.requestHandler = { req in
        XCTAssertNil(req.value(forHTTPHeaderField: "Authorization"),
                     "/q/* requests must not have an Authorization header")
        return (Data(), HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
    _ = try await sut.data(for: request)
}

// Verify /version path receives no Authorization header
func test_data_versionPath_doesNotAddBearerToken() async throws {
    let request = URLRequest(url: URL(string: "https://api.bodymetric.com.br/version")!)
    // ... similar to above
}
```

---

## What is NOT changing

- `TokenRefreshCoordinator` — serialization logic is correct; no changes
- `KeychainService` — storage is correct; no changes
- `AuthService` — sign-out and force-logout are correct; no changes
- `TokenRefreshResponse` / `TokenExchangeResponse` — CodingKeys are correct; no changes
- All 401 retry, forced logout, and session persistence logic — all correct and tested
