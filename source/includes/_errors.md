# Errors
Error messages are returned in JSON format. For example, an error might look like this:

```json
{
  "errors": [
    {
      "message": "Invalid parameter email",
      "locations": [
        {
          "line": 2,
          "column": 3
        }
      ],
      "path": [
        "job_createJob"
      ],
      "extensions": {
        "invalidFields": {
          "email": "INVALID_FORMAT"
        },
        "code": "BAD_USER_INPUT",
        "exception": {
          "invalidFields": {
            "email": "INVALID_FORMAT"
          }
        }
      }
    }
  ],
}
```

## Global Authentication Error Codes

The error code can be found in `errors[index].extensions.code`
The error message can be found in `errors[index].message`

|Code|Text|Description|
|--- |--- |--- |
|INVALID_ACCESS_TOKEN|  Invalid token|  Your access token is invalid or missing
|EXPIRED_ACCESS_TOKEN|  Access Token Expired| The JWT provided is older than 30 seconds
|FORBIDDEN| Access denied|  JWT format correct but incorrect permisions
|KEYS_NOT_FOUND|  Keys not found| Keys must be provided and the correct ones
|UNKNOWN_ERROR| various messages| An unknown error occurred, please check the error message for more information

## Global Logic Error Codes

The error code can be found in `errors[index].extensions.code`
The error message can be found in `errors[index].message`

|Code|Text|Description|
|--- |--- |--- |
|JOB_CREATION_LIMIT_REACHED|  Daily jobs creation limit reached| You've reached your daily limit of job creation, please try again the next day.
