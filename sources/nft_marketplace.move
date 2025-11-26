module simple_market::marketplace 
    use sui::tx_context::{self, TxContext};
    use sui::transfer;
    use sui::object;
    use sui::event;
    use std::string;

   
    //   SIMPLE NFT STRUCT
    struct MyNFT has key {
        id: object::ID,
        name: string::String,
        owner: address,
    }

   
    //   LISTING STRUCT (HOLDS NFT + PRICE)
    struct Listing has key {
        id: object::ID,
        nft: MyNFT,
        seller: address,
        price: u64,
    }

    //   EVENTS (JUST FOR BACKEND INDEXING)
    struct MintEvent has copy, drop, store {
        nft_id: object::ID,
        owner: address,
    }

    struct ListEvent has copy, drop, store {
        listing_id: object::ID,
        nft_id: object::ID,
        seller: address,
        price: u64,
    }

    struct BuyEvent has copy, drop, store {
        listing_id: object::ID,
        nft_id: object::ID,
        buyer: address,
        price: u64,
    }


    //   MINT NFT
    public entry fun mint(name: string::String, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);

        let nft = MyNFT {
            id: object::new(ctx),
            name,
            owner: sender,
        };

        // Emit event
        event::emit(MintEvent {
            nft_id: object::id(&nft),
            owner: sender
        });

        // Send NFT to user
        transfer::public_transfer(nft, sender);
    }

    //   LIST NFT (MOVE INTO LISTING)
    public entry fun list_nft(nft: MyNFT, price: u64, ctx: &mut TxContext): Listing {
        let sender = tx_context::sender(ctx);

        let listing = Listing {
            id: object::new(ctx),
            nft,
            seller: sender,
            price,
        };

        event::emit(ListEvent {
            listing_id: object::id(&listing),
            nft_id: object::id(&listing.nft),
            seller: sender,
            price,
        });

        listing
    }

    //   BUY NFT
    public entry fun buy(listing: Listing, ctx: &mut TxContext) {
        let buyer = tx_context::sender(ctx);
        let nft_id = object::id(&listing.nft);
        let price = listing.price;
        let listing_id = object::id(&listing);

        // Transfer NFT to buyer
        let mut nft = listing.nft;
        nft.owner = buyer;
        transfer::public_transfer(nft, buyer);

        // Emit event
        event::emit(BuyEvent {
            listing_id,
            nft_id,
            buyer,
            price,
        });

        // Listing is consumed (deleted) automatically because it's moved in.
    }

