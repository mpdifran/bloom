# Bloom-Backend

The source code for Bloom's backend, built using Vapor.

## Environment

Place a `.env` file in the same directory as this README to export environment variables. This file is automatically ignored by git.

## Local Debugging

### Postman

You can use Postman to hit endpoints on your localhost when you run the project in Xcode. The base URL is printed in the console upon launch.

```
http://127.0.0.1:8080
```

### Real iOS Device

1. Sign up for a free account for [ngrok](https://dashboard.ngrok.com/signup).
2. Download the desktop client, and get ngrok running.
3. Run this command to forward requests to `localhost`.

```
ngrok http http://localhost:8080
```

4. Copy the URL associated with the Forwarding field. (Should be something like `https://<random charcters>.ngrok-free.app`)
5. In Bloom, go to the User Profile screen, scroll down and select Developer Tools.
6. Enable "Override Host", then paste the URL in the Host field.

Bloom on your device will now send requests to your local machine.

### Redis
Install Redis locally using the following command:

```
brew install redis
```

Run Redis as a background service using the following:

```
brew services start redis
```

-or- Run Redis temporarily in the terminal with the following:

```
/opt/homebrew/opt/redis/bin/redis-server /opt/homebrew/etc/redis.conf
```

## Reverting the Database

If you're making database changes locally, and you want to undo a recent new migration, you can run the following script:

```
./revert.sh
```

This will undo only the single most recent migration. You can run it multiple times to undo multiple migrations. 

> NOTE: Do not bother reverting a change already deployed to production. It's too much of a headache, just create another migration.
