# KCAuth

Keycloak Elixir integration for multi-tenant single page apps.

## Starting the application

In your supervision tree, add the following:

```
  {KCAuth, otp_app: <your_otp_app_name>}
```

In your config, add the following:

```
  config :your_otp_app_name, KCAuth,
      url: "http://127.0.0.1:32768",
```

## Verifying tokens

```
  {:ok, jwt, realm} = KCAuth.verify(Some_jwt_token)

```

## Keycloak test setup

### Running a test keycloak server

Setting the admin credentials for testing. Used later to add realm ea.

```
ADMIN_USER=admin
ADMIN_PASS=admin
```

Start the container exposing all ports

```
docker run \
  --name=keycloak \
  -e KEYCLOAK_USER=${ADMIN_USER} \
  -e KEYCLOAK_PASSWORD=${ADMIN_PASS} \
  -dP \
  jboss/keycloak:4.0.0.Final
```


### Add a new REALM

```
REALM=sso-dev
```

Login as admin (ensure credentials are set in the env !)

```
docker exec -it keycloak /opt/jboss/keycloak/bin/kcadm.sh \
  config credentials \
    --server http://localhost:8080/auth \
    --realm master \
    --user ${ADMIN_USER} \
    --password ${ADMIN_PASS}
```

Create the REALM  

```
docker exec -it keycloak /opt/jboss/keycloak/bin/kcadm.sh \
  create realms -o \
    -s realm=${REALM} \
    -s enabled=true \
    \
    -s registrationAllowed=true \
    -s rememberMe=true \
    -s resetPasswordAllowed=true \
    -s internationalizationEnabled=true \
    -s 'supportedLocales=["de","no","ru","sv","pt-BR","lt","en","it","fr","zh-CN","es","ja","ca","nl"]' \
    \
    -s revokeRefreshToken=false \
    -s ssoSessionIdleTimeout=7200 \
    -s ssoSessionMaxLifespan=36000 \
    -s offlineSessionIdleTimeout=2592000 \
    -s accessTokenLifespan=300 \
    -s accessTokenLifespanForImplicitFlow=900 \
    \
    -s bruteForceProtected=true
```

Add a test user

```
docker exec -it keycloak /opt/jboss/keycloak/bin/kcadm.sh \
  create users -o \
    -r ${REALM} \
    -s username="${REALM}-1" \
    -s enabled=true

docker exec -it keycloak /opt/jboss/keycloak/bin/kcadm.sh \
  set-password \
    -r ${REALM} \
    --username "${REALM}-1" \
    --new-password "${REALM}-1"
```

Add a client

```
docker exec -it keycloak /opt/jboss/keycloak/bin/kcadm.sh \
  create clients -o \
    -r ${REALM} \
    -s clientId=sso-dev \
    -s name="SSO Dev" \
    -s enabled=true \
    -s publicClient=true \
    -s standardFlowEnabled=true \
    -s implicitFlowEnabled=false \
    -s directAccessGrantsEnabled=true \
    -s 'redirectUris=["http://127.0.0.1:4200/*"]' \
    -s 'webOrigins=["+"]'
```

