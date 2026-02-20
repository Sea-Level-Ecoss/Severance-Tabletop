# GrilwurtBot API Contract (Milestone 1)

## Base URL

- Configured in TTS Global script.
- Example: http://localhost:8787

## Endpoints

### List Cards

- GET /api/cards
- Optional filters:
  - ?status=all (or a specific status)
  - ?type={card_type}
  - ?taxonomy_rank={rank}&taxonomy_member={member}

Response:

- { ok: true, cards: CardRecord[] }

### Get Card by ID

- GET /api/cards/{id}

Response:

- { ok: true, card: CardRecord }

## CardRecord Fields (Observed)

- id
- display_name
- card_type
- description
- taxonomy_rank
- taxonomy_member
- rarity
- weapon_class
- weapon_subtype
- ammo_type
- resource_cost
- tags
- keywords
- taxonomy_table
- image_path
- completion_status
- completion_percentage
- missing_parameters
- created_at
- updated_at

## Image Strategy (Draft)

The API returns image_path. For TTS we need a URL.

Assumptions (choose one and standardize):

1) image_path already contains a public URL.
2) GrilwurtBot exposes a static image base URL such as:
  - http://localhost:8787/images/ss_cards/{id}.png

If neither exists, add a small proxy endpoint to GrilwurtBot that serves card images by id.

## Taxonomy Ranks (Reference)

Used by Presence/Absence deckbuilding order:

- Bin
- Basin
- Eco
- Kingdom
- Phylum
- Class
- Order
- Family
- Essa

## Status Filter Recommendation

- Default to status=all for development.
- Optionally use status=gameplay_ready for playtests.
