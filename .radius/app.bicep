extension radius

param environment string

@secure()
param mysqlPassword string

@secure()
param registryPassword string

@secure()
param registryUsername string

resource simpleTodo3App 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'simple-todo-app-3'
  properties: {
    environment: environment
  }
}

resource mysqlDb 'Radius.Data/mySqlDatabases@2025-08-01-preview' = {
  name: 'mysql'
  properties: {
    environment: environment
    application: simpleTodo3App.id
    codeReference: 'src/persistence/mysql.js#L31'
    database: 'todos'
    version: '8.0'
    username: 'myadmin'
    password: mysqlPassword
  }
}

resource mysqlClientCredentials 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'mysql-client-credentials'
  properties: {
    environment: environment
    application: simpleTodo3App.id
    codeReference: 'src/persistence/mysql.js#L10'
    data: {
      password: {
        value: mysqlPassword
      }
    }
  }
}

resource registryCreds 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'radius-ghcr-registry-creds'
  properties: {
    environment: environment
    application: simpleTodo3App.id
    codeReference: '.radius/app.bicep#L48'
    data: {
      password: {
        value: registryPassword
      }
      username: {
        value: registryUsername
      }
    }
  }
}

resource simpleTodo3Image 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'simple-todo-app-3-image'
  properties: {
    environment: environment
    application: simpleTodo3App.id
    codeReference: 'Dockerfile#L1'
    tag: '5a6fbf5caf98'
    build: {
      source: 'git::https://github.com/ryanwaite/simple-todo-app-3.git?ref=5a6fbf5caf982f1d928fe6c1c32aa74f1e95e063'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource simpleTodo3Container 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'simple-todo-app-3'
  properties: {
    environment: environment
    application: simpleTodo3App.id
    codeReference: 'src/index.js#L18'
    containers: {
      simpleTodo3: {
        image: simpleTodo3Image.properties.imageReference
        env: {
          MYSQL_DB: {
            value: 'todos'
          }
          MYSQL_HOST: {
            value: mysqlDb.properties.host
          }
          MYSQL_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: mysqlClientCredentials.name
                key: 'password'
              }
            }
          }
          MYSQL_USER: {
            value: 'myadmin'
          }
        }
        ports: {
          web: {
            containerPort: 3000
          }
        }
      }
    }
  }
}
