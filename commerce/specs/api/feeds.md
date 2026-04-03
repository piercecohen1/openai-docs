# Feeds

<a
    href="https://github.com/agentic-commerce-protocol/agentic-commerce-protocol"
    target="_blank"
    rel="noopener noreferrer"
    class="underline"
  >
    This spec is in a draft state for feedback till 04/07/2026. Feedback is
    welcome in the ACP github repo.
  </a>

## Overview

Use these endpoints to create a product feed and retrieve feed metadata.

## REST endpoints

- <code>GET /product_feeds/&#123;id&#125;</code> returns metadata for a feed.
- <code>POST /product_feeds</code> creates a new product feed and returns its
  metadata.

### **GET /product_feeds/&#123;id&#125;**

Returns metadata for the specified product feed.

#### Path parameters

| Field | Type     | Required | Description                      |
| :---- | :------- | :------- | :------------------------------- |
| `id`  | `string` | Yes      | Identifier for the product feed. |

#### Request

This endpoint does not define a request body.

#### Response

`200 OK`

| Field            | Type     | Required | Description                                      |
| :--------------- | :------- | :------- | :----------------------------------------------- |
| `id`             | `string` | Yes      | Identifier for the product feed.                 |
| `target_country` | `string` | No       | Two letter country code per ISO 3166.            |
| `updated_at`     | `string` | No       | Timestamp of the most recent update to the feed. |

`404 Not Found`

Returned when the product feed is not found.

### **POST /product_feeds**

Creates a new product feed and returns its metadata.

#### Request

| Field            | Type     | Required | Description                           |
| :--------------- | :------- | :------- | :------------------------------------ |
| `target_country` | `string` | No       | Two letter country code per ISO 3166. |

#### Response

`200 OK`

| Field            | Type     | Required | Description                                      |
| :--------------- | :------- | :------- | :----------------------------------------------- |
| `id`             | `string` | Yes      | Identifier for the product feed.                 |
| `target_country` | `string` | No       | Two letter country code per ISO 3166.            |
| `updated_at`     | `string` | No       | Timestamp of the most recent update to the feed. |

`400 Bad Request`

Returned when the product feed payload is invalid.