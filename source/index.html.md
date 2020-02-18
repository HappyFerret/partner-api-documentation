---
title: Local Heroes API Documentation

language_tabs: # must be one of https://git.io/vQNgJ
  - typescript
  # - graphql
  - shell

toc_footers:
  # - <a href='#'>Sign Up for a Developer Key</a>
  # - <a href='https://github.com/slatedocs/slate'>Documentation Powered by Slate</a>

includes:
  - errors

search: true
---

# Introduction

Welcome to the Local Heroes developer page. Our API allows affiliates/partners to send leads directly to the Local Heroes platform. Our API uses GraphQL over HTTPS, and is secured using JSON Web Tokens (JWTs).

## Before integrating you should:

* Have a commercial agreement with us regarding the leads you will send
* Have an understanding of which taxonomies you are subscribed to
* Have a Partner ID
* Have a basic understanding of [GraphQL](https://graphql.org/) and [JWT](https://jwt.io/)

If you have any questions, please email apiteam@localheroes.com or speak to your Local Heroes account manager.

## Discover the schema

You should use a GraphQL discovery tool to see our schema and all the properties available.
Our schema url is `https://services.localheroes.com/graphql`
We recommend three:

* [FireCamp](https://firecamp.io/)
* [GraphQL Playground](https://github.com/prisma-labs/graphql-playground)
* [GraphQL Bin (public)](https://www.graphqlbin.com/v2/new)

## Generating your keys

> To generate the keys with shell

```
ssh-keygen -t rsa -b 2048 -f ./jwt.key -m PEM && ssh-keygen -f jwt.key.pub -e -m pkcs8
```

After your public/private key pair is generated, please send us your public key and store your private key securely.
If this doesn't work on your machine you might like to try using Docker (see below)

### Using Docker to generate keys

> To generate the keys with docker

```
docker run -it -v $(pwd):/export frapsoft/openssl genrsa -aes256 -out /export/jwt.key
docker run -it -v $(pwd):/export frapsoft/openssl rsa -in /export/jwt.key -pubout -outform PEM -out /export/jwt.key.pub
```

If you are having problems generating keys from your native OS, you can try using the Docker container [frapsoft/openssl](https://hub.docker.com/r/frapsoft/openssl/).

You should then have the public / private key files in your local filesystem.

# Authentication

The LocalHeroes API expects a brand new JWT for each API calls. This JWT has to expire in no more than 10min from it's "issued at" date.

`Authorization: Bearer ${YOUR_JWT}`

<aside class="notice">
You must replace <code>${YOUR_JWT}</code> with the JWT you generated for this request.
</aside>

## JWTs format

> Header

```json
{
  "alg": "RS256",
  "typ": "JWT"
}
```

> Payload

```json
{
  "iss": "partner",
  "aud": "LocalHeroes",
  "lh:partner": "PARTNER_ID",
  "iat": "ISSUED_AT_DATE",
  "sub": "PARTNER_ID",
  "environment": "SANDBOX || PRODUCTION"
}
```

Properties to update in the Payload:

* `lh:partner`: The partner ID provided by LocalHeroes
* `sub`: The partner ID provided by LocalHeroes
* `iat`: The date the JWT was issued
* `environment`: Use "SANDBOX" for testing and "PRODUCTION" for production environment.

## Generating JWTs

```typescript
import * as jwt from 'jsonwebtoken';

export default function generateJWT(): string {
  const JWTHeader = {
    alg: 'RS256',
    typ: 'JWT',
  };
  const now = Math.floor(Date.now() / 1000);

  const JWTPayload = {
    iss: 'partner',
    aud: 'LocalHeroes',
    iat: now,
    exp: now + 600,
    sub: '12345',
    'lh:partner': '12345',
  };

  return jwt.sign(JWTPayload, Buffer.from('privateKey', 'utf8'), {
    algorithm: 'RS256',
    header: JWTHeader,
  });
}
```

Example on how to generate a JWT with Typescript

# Coverage

## Coverage by taxonomy

```typescript
interface CoverageByTaxonomyVariables {
  area: string;
  taxonomyId: string;
}
interface CoverageByTaxonomyResponse {
  coverageByTaxonomy: boolean;
}

const coverageByTaxonomyQuery = gql`
  query YOUR_COMPANY_NAME_coverageByTaxonomy($area: String!, $taxonomyId: String!) {
    coverageByTaxonomy(area: $area, taxonomyId: $taxonomyId)
  }
`;
const client = getClient();

const response = await client.query<CoverageByTaxonomyResponse, CoverageByTaxonomyVariables>({
  query: coverageByTaxonomyQuery,
  variables: { taxonomyId, area }
});
```

<!-- ```graphql
query {
  coverageByTaxonomy(area:"sa99", taxonomyId:"lhrn:uk:taxonomy:xxx/xxxx")
}
``` -->

```shell
curl 'https://services.localheroes.com/graphql'
  -H "Authorization: ${YOUR_JWT}"
  -H 'Content-Type: application/json'
  -H 'Accept: application/json'
  --data-binary '{"query":"query coverageByTaxonomy{\n  coverageByTaxonomy(area:\"sa99\", taxonomyId:\"lhrn:uk:taxonomy:xxx/xxxx\")\n}"}'
  --compressed
```

> The above request returns JSON structured like this:

```json
{
  "data": { "coverageByTaxonomy": true }
}
```

The response can be one of three values:

* `true` - We do have coverage
* `false` - We do not have coverage
* An error condition reported in the error object. E.g. 'high demand'. In exceptional circumstances we may report high demand for a particular speciality in a localized area. If this happens we will not take on any more jobs, as the chances of finding a trader are low. It is better that we let the customer know ASAP, so that they can look elsewhere.

### Variables

| Name  | Optional | Notes | Type |
| - | - | - | - |
| area | NO | The post code area  | String |
| taxonomyId | NO | The given taxonomy Id | String |

### HTTP Request

`POST https://services.localheroes.com/graphql`

### HTTP Headers

- `Authorization: Bearer JWT_TOKEN_HERE`
- `Referrer: YOUR_COMPANY_NAME`
- `Content-Type: application/json`

# Job

## Create a job

```typescript
interface CreateJobVariables {
  input: {
    job: {
        postCode: string;
        taxonomyId: string;
        address1: string;
        timeslots?: [{
          startDateTime: Date;
          endDateTime: Date;
        }],
        description: string;
        address2?: string;
        address3?: string;
        quote?: {
          type: HOURS|FIXED;
          description: string;
          labourQty: number;
          labourRate: number;
          labourCost: number;
          partsCost: number;
          approvedByCustomer: boolean;
        }
      },
      customer: {
        email: string;
        mobile: string;
        firstName: string;
        lastName: string;
        acceptTandCs: boolean;
        optIn: boolean;
      },
  }
}
interface CreateJobResponse {
  id: number;
}

const createJobMutation = gql`
  mutation YOUR_COMPANY_NAME_createJob($input: job_InputCreateJob!) {
    job_createJob(input: $input) { id }
  }
`;
const client = getClient();

const response = await client.mutate<CreateJobVariables, CreateJobResponse>({
  mutation: createJobMutation,
  variables: {
    input: {
      job: {
        postCode: "SA99 1AA",
        taxonomyId: "lhrn:uk:taxonomy:xxx/xxx",
        address1: "CUSTOMER_ADDRESS_LINE_1",
        timeslots: {
          startDateTime: "2020-02-13T08:00:00Z",
          endDateTime: "2020-02-13T12:00:00Z",
        },
        description: "JOB_DESCRIPTION",
        address2: "CUSTOMER_ADDRESS_LINE_2",
        address3: "CUSTOMER_ADDRESS_LINE_3",
      },
      customer: {
        email: "CUSTOMER_EMAIL",
        mobile: "CUSTOMER_MOBILE_NUMBER",
        firstName: "CUSTOMER_FIRST_NAME",
        lastName: "CUSTOMER_LAST_NAME",
        acceptTandCs: true,
        optIn: false,
      },
    }
  }
});
```

```shell
curl 'https://services.localheroes.com/graphql'
  -H 'Content-Type: application/json' 
  -H 'Accept: application/json' 
  -H 'Authorization: Bearer ${YOUR_JWT_HERE}'
  --data-binary '{"query":"mutation TO_BE_CHANGED_createJob($input: job_InputCreateJob!) {\n    job_createJob(input: $input) { id }\n  }","variables":{"input":{"job":{},"customer":{}}}}'
  --compressed
```

> The above command returns JSON structured like this:

```json
{
  "data": {
    "id": 123
  }
}
```

The response will be the job id in that case but a lot more properties are available (please use a GraphQL tool to see the available properties see [Discover the schema](#discover-the-schema))

### Sandbox

We recommend that you first try creating a Job using our API Sandbox.
We use the following Special postcodes for error triggering:

| PostCode  | Error |
| ------------- | ------------- |
| SA99 1AA  | Area not covered  |
| SA99 1AB  | Daily jobs creation limit reached  |
| SA99 1AD  |	Request not authorized|

### Variables

| Name  | Optional | Notes | Type |
| - | - | - | - |
| job.postCode | NO | The space in the middle is not necessary  | String |
| job.address1 | NO | Limit: 255 characters | String |
| job.address2 | YES | Limit: 255 characters | String |gi
| job.address3 | YES | Limit: 255 characters | String |
| job.description | YES | Limit: 1024 characters | String |
| job.taxonomyId | NO | Provided by LocalHeroes | String |
| job.timeSlot | YES | The array containing the timeSlots | Array |
| job.timeSlot.startDateTime | NO | The start time of the timeSlot - If none given then value should be null | String |
| job.timeSlot.endDateTime | NO | The end time of the timeSlot - If none given then value should be null | String |
| job.quote | YES | The object containing the quote information | Object |
| job.quote.type | NO | The quote type (HOURS or FIXED) | Enum |
| job.quote.description | NO | The quote description | String |
| job.quote.labourQty | NO | The quote labour quantity | Number |
| job.quote.labourRate | NO | The quote labour rate | Number |
| job.quote.labourCost | NO | The quote labour cost | Number |
| job.quote.partsCost | NO | The quote parts cost | Number |
| job.quote.approvedByCustomer | NO | If the quote has been approved by the customer | Boolean |
| customer.mobile	|NO|	Mobile and landline numbers accepted| String |
| customer.firstName |NO|	First name of customer| String |
| customer.lastName |NO|	Last name of customer| String |
| customer.email	|NO	|Email of customer for contact purposes| String |

### HTTP Request

`POST https://services.localheroes.com/graphql`

### HTTP Headers

- `Authorization: Bearer JWT_TOKEN_HERE`
- `Referrer: YOUR_COMPANY_NAME`
- `Content-Type: application/json`

### Error Codes

The error code can be found in `errors[index].extensions.code`
The error message can be found in `errors[index].message`

|Code|Text|Description|
|--- |--- |--- |
|BAD_USER_INPUT|  Invalid parameter [list of parameters (example: firstName, lastName)]|  One of the following input is badly formatted (INVALID_FORMAT) or empty (EMPTY)
|NOT_AUTHORIZED|  You are not authorized to create this type of job|  You do not have the permissions to create that type of job. Please contact your LocalHeroes representative
|NOT_AUTHORIZED|  You do not have permission to skip the coverage check|  You do not have the permissions to skip the coverage check. Please contact your LocalHeroes representative
|AREA_NOT_COVERED|  Area not covered| We do not have any hero available to cover this area
|TRADER_NOT_ELIGIBLE| Trader with id: {{TRADER_ID}} is not eligible for this job|  The assigned trader is not eligible to cover this type of work in this area
|JOB_CREATION_ERROR|  Failed to create job: {{error}}|  There was an error creating the job, please see the message for more information

## Cancel a Job

```typescript
interface CancelJobVariables {
  partnerJobRef: string;
  reason?: string;
}
interface CancelJobResponse {
  job_cancelJobByPartnerJobRef: boolean;
}

const cancelJobByPartnerJobRefMutation = gql`
  mutation YOUR_COMPANY_NAME_cancelJob($partnerJobRef: String!, $reason: String) {
    job_cancelJobByPartnerJobRef(partnerJobRef: $partnerJobRef, reason: $reason)
  }
`;
const client = getClient();

const response = await client.mutate<CancelJobResponse, CancelJobVariables>({
  mutation: cancelJobByPartnerJobRefMutation,
  variables: { partnerJobRef, reason }
});
```

```shell
curl 'https://services.localheroes.com/graphql'
  -H 'Content-Type: application/json'
  -H 'Accept: application/json'
  -H 'Authorization: Bearer ${YOUR_JWT_HERE}'
  --data-binary '{"query":"mutation YOUR_COMPANY_NAME_cancelJob($partnerJobRef: String!, $reason: String) {\n    job_cancelJobByPartnerJobRef(partnerJobRef: $partnerJobRef, reason: $reason)\n  }","variables":{"partnerJobRef":"1234","reason":"A reason"}'
  --compressed
```

> The above command returns JSON structured like this:

```json
{
  "data": {
    "job_cancelJobByPartnerJobRef": true
  }
}
```

The response can be one of two values:

* `true` - The job has been cancelled
* An error condition reported in the error object.

### Variables

| Name  | Optional | Notes | Type |
| - | - | - | - |
| partnerJobRef | NO | Limit: 255 characters  | String |
| reason | YES | Limit: 255 characters | String |

### HTTP Request

`POST https://services.localheroes.com/graphql`

### HTTP Headers

- `Authorization: Bearer JWT_TOKEN_HERE`
- `Referrer: YOUR_COMPANY_NAME`
- `Content-Type: application/json`

### Error Codes

The error code can be found in `errors[index].extensions.code`
The error message can be found in `errors[index].message`

|Code|Text|Description|
|--- |--- |--- |
|JobNotCancellable| Can't cancel job with job id ${id} because it has an active loan| This job is not cancellable because the customer has applied for finance on it|

## Reschedule a Job

```typescript
interface RescheduleJobVariables {
  partnerJobRef: string;
  timeslot: {
    startDateTime: Date;
    endDateTime: Date;
  };
}
interface RescheduleJobResponse {
  job_rescheduleJobByPartnerJobRef: boolean;
}

const rescheduleJobByPartnerJobRefMutation = gql`
  mutation YOUR_COMPANY_NAME_rescheduleJob(partnerJobRef: String!, timeslot: job_InputTimeslot) {
    job_rescheduleJobByPartnerJobRef(partnerJobRef: $partnerJobRef, timeslot: $timeslot)
  }
`;
const client = getClient();

const response = await client.mutate<RescheduleJobResponse, RescheduleJobVariables>({
  mutation: rescheduleJobByPartnerJobRefMutation,
  variables: { partnerJobRef, timeslot }
});
```

```shell
curl 'https://services.localheroes.com/graphql'
  -H 'Content-Type: application/json'
  -H 'Accept: application/json'
  -H 'Authorization: Bearer ${YOUR_JWT_HERE}'
  --data-binary '{"query":"mutation YOUR_COMPANY_NAME_rescheduleJob(partnerJobRef: String!, timeslot: job_InputTimeslot) {\n    job_rescheduleJobByPartnerJobRef(partnerJobRef: $partnerJobRef, timeslot: $timeslot)\n  }","variables":{"partnerJobRef":"1234","timeslot":[{"startDateTime": "2020-01-01T08:00:00.000Z", "endDateTime": "2020-01-01T012:00:00.000Z"}]}'
  --compressed
```

> The above command returns JSON structured like this:

```json
{
  "data": {
    "job_rescheduleJobByPartnerJobRef": true
  }
}
```

The response can be one of two values:

* `true` - The job has been rescheduled
* An error condition reported in the error object.

### Variables

| Name  | Optional | Notes | Type |
| - | - | - | - |
| partnerJobRef | NO | Limit: 255 characters  | String |
| timeslot | NO | The timeslot object | Object |
| timeslot.startDateTime | NO | The start time of the timeSlot - If none given then value should be null | String |
| timeslot.endDateTime | NO | The end time of the timeSlot - If none given then value should be null | String 

### HTTP Request

`POST https://services.localheroes.com/graphql`

### HTTP Headers

- `Authorization: Bearer JWT_TOKEN_HERE`
- `Referrer: YOUR_COMPANY_NAME`
- `Content-Type: application/json`
