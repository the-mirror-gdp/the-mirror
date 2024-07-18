const { ObjectId } = require('mongodb')

const { Stripe } = require('stripe')
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
  apiVersion: '2022-11-15'
})

const MIGRATION_SCRIPT_NAME = '20240401110610-add-products-for-purchaseOptions'

module.exports = {
  async up(db, client) {
    const assetsCollection = db.collection('assets')
    const migrationScriptKey = `migrationScript.${MIGRATION_SCRIPT_NAME}`

    // Get all assets with purchaseOptions
    const assets = await assetsCollection
      .find({ purchaseOptions: { $exists: 1 } })
      .toArray()
    const bulkOps = []
    assets.forEach(async (asset) => {
      for (let i = 0; i < asset.purchaseOptions.length; i++) {
        const purchaseOption = asset.purchaseOptions[i]

        // Check if the purchaseOption has an _id and is enabled
        if (
          purchaseOption._id &&
          purchaseOption.enabled &&
          purchaseOption.type === 'ONE_TIME'
        ) {
          try {
            // Create a product and price in Stripe
            await stripe.products.create({
              id: purchaseOption._id.toString(),
              name: asset.name,
              description:
                asset.description === '' ? asset.name : asset.description,
              default_price_data: {
                currency: 'usd',
                unit_amount: Number(purchaseOption.price) * 100
              }
            })

            bulkOps.push({
              updateOne: {
                filter: { _id: asset._id },
                update: {
                  $set: {
                    [migrationScriptKey]: true
                  }
                }
              }
            })
          } catch (error) {
            console.log(error)
          }
        } else {
          const key = `purchaseOptions.$[${i}]`
          // Check if the purchaseOption has a price and is a ONE_TIME type
          if (
            !purchaseOption._id &&
            purchaseOption.price &&
            purchaseOption.type === 'ONE_TIME'
          ) {
            // Create a new ObjectId for the product
            const newId = new ObjectId()

            try {
              // Create a product and price in Stripe
              await stripe.products.create({
                id: newId.toString(),
                name: asset.name,
                description:
                  asset.description === '' ? asset.name : asset.description,
                default_price_data: {
                  currency: 'usd',
                  unit_amount: Number(purchaseOption.price) * 100
                }
              })

              bulkOps.push({
                updateOne: {
                  filter: { _id: asset._id },
                  update: {
                    $set: {
                      [migrationScriptKey]: true,
                      [`${key}._id`]: newId
                    }
                  }
                }
              })
            } catch (error) {
              console.log(error)
            }
          }
        }
      }
    })
    if (bulkOps.length) {
      await assetsCollection.bulkWrite(bulkOps)
    }
  },

  async down(db, client) {
    const assetsCollection = db.collection('assets')
    const migrationScriptKey = `migrationScript.${MIGRATION_SCRIPT_NAME}`

    const assets = await assetsCollection
      .find({ [migrationScriptKey]: true })
      .toArray()

    const bulkOps = []
    for (let j = 0; j < assets.length; j++) {
      const asset = assets[j]
      for (let i = 0; i < asset.purchaseOptions.length; i++) {
        const purchaseOption = asset.purchaseOptions[i]
        if (
          purchaseOption._id &&
          purchaseOption.enabled &&
          purchaseOption.type === 'ONE_TIME'
        ) {
          await stripe.products.update(purchaseOption._id.toString(), {
            active: false
          })

          bulkOps.push({
            updateOne: {
              filter: { _id: asset._id },
              update: {
                $unset: {
                  [migrationScriptKey]: true
                }
              }
            }
          })
        }
      }
    }

    if (bulkOps.length) {
      await assetsCollection.bulkWrite(bulkOps)
    }
  }
}
