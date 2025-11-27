module simple_market::marketplace {
    use sui::tx_context;
    use sui::transfer;
    use sui::object;
    use sui::event;
    use sui::coin;
    use sui::sui::SUI;
    use std::string;

    // ========== STRUCTS ==========

    /// A simple NFT
    public struct MyNFT has key, store {
        id: object::UID,
        name: string::String,
        owner: address,
    }

    /// A marketplace listing
    public struct Listing has key, store {
        id: object::UID,
        nft: MyNFT,
        price: u64,
        seller: address,
    }

    // ========== EVENTS ==========
    public struct MintEvent has copy, drop { nft_id: object::ID, owner: address, name: string::String }
    public struct ListEvent has copy, drop { listing_id: object::ID, seller: address, price: u64 }
    public struct BuyEvent has copy, drop { listing_id: object::ID, seller: address, buyer: address, price: u64 }

    // ERRORS 
    const ENOT_OWNER: u64 = 0;
    const EINSUFFICIENT_PAYMENT: u64 = 1;

    // FUNCTIONS 
    /// Mint NFT
    public entry fun mint_nft(name: string::String, ctx: &mut tx_context::TxContext) {
        let sender = tx_context::sender(ctx);
        let nft = MyNFT { id: object::new(ctx), name, owner: sender };

        event::emit(MintEvent {
            nft_id: object::id(&nft),
            owner: sender,
            name: nft.name,
        });

        transfer::public_transfer(nft, sender);
    }

    /// List NFT for sale
    public entry fun list_nft(nft: MyNFT, price: u64, ctx: &mut tx_context::TxContext) {
        let sender = tx_context::sender(ctx);
        assert!(nft.owner == sender, ENOT_OWNER);

        let listing = Listing { id: object::new(ctx), nft, price, seller: sender };

        event::emit(ListEvent {
            listing_id: object::id(&listing),
            seller: sender,
            price,
        });

        transfer::public_transfer(listing, sender);
    }

    /// Buy a listed NFT
       /// Buy a listed NFT
    public entry fun buy(
        listing: Listing,
        payment: coin::Coin<SUI>,
        ctx: &mut tx_context::TxContext
    ) {
        let buyer = tx_context::sender(ctx);

        // Take ownership by destructuring Listing
        let Listing { id, nft, price, seller } = listing;

        // Check correct payment amount
        let paid_amount = coin::value(&payment);
        assert!(paid_amount == price, EINSUFFICIENT_PAYMENT);

        // Pay seller with public transfer
        transfer::public_transfer(payment, seller);

        // Transfer NFT to buyer (update owner field)
        let mut nft = nft;
        nft.owner = buyer;
        transfer::public_transfer(nft, buyer);

        // Emit buy event
        event::emit(BuyEvent {
            listing_id: object::uid_to_inner(&id),
            seller,
            buyer,
            price,
        });

        // Delete listing's UID
        object::delete(id);
    }

    // Cancel a listing
    
}
