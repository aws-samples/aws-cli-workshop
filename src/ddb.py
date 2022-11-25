import uuid
from typing import Optional
from dataclasses import dataclass, field, asdict

import boto3
from boto3.dynamodb.conditions import Key


@dataclass
class ProductReview:
    name: str
    rating: int
    review: str
    url: Optional[str] = None
    product_id: str = field(default_factory=lambda: str(uuid.uuid4()))


class DDBClient:
    def __init__(self, app=None):
        self._table = None
        if app is not None:
            self.init_app(app)

    @property
    def table(self):
        return self._table

    def init_app(self, app, **kwargs):
        self._table = boto3.resource('dynamodb').Table(
            app.config['DDB_TABLE_NAME'])

    # We should split this out in to separate classes
    # (client vs. app specific model objects).

    # PK=reviews, SK=product#{product_id}

    def create_review(self, review: ProductReview):
        item = {
            'PK': 'REVIEWS',
            'SK': f'PRODUCT#{review.product_id}',
            **asdict(review),
        }
        self.table.put_item(Item=item)

    def get_reviews(self):
        final = []
        results = self.table.query(
            KeyConditionExpression=(
                Key('PK').eq('REVIEWS') &
                Key('SK').begins_with('PRODUCT#')
            )
        )
        for result in results.get('Items', []):
            result.pop('PK', None)
            result.pop('SK', None)
            final.append(ProductReview(**result))
        return final
