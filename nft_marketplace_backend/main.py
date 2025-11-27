from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
from sui_python_sdk.wallet import SuiWallet
from sui_python_sdk.provider import SuiJsonRpcProvider
from sui_python_sdk.signer_with_provider import SignerWithProvider

import os

app = FastAPI(title="Simple NFT Marketplace Backend")

#  Sui client 
SUI_RPC_URL = os.getenv("SUI_RPC_URL", "https://fullnode.devnet.sui.io")
provider = SuiJsonRpcProvider(SUI_RPC_URL)

PACKAGE_ID = "0x2a61f9083d32bfc9ad2883250b54f792ad2b53a0437a2f7d2724ef0bb02ba670"
MODULE_NAME = "marketplace"

# Models 
class NFT(BaseModel):
    id: str
    name: str
    owner: str

class Listing(BaseModel):
    id: str
    nft: NFT
    price: int
    seller: str
    
class ListRequest(BaseModel):
    nft_id: str
    price: int
    seller: str  

class BuyRequest(BaseModel):
    listing_id: str
    buyer: str   
    payment_id: str 


class MintRequest(BaseModel):
    name: str
    owner: str  

#  Endpoints 
@app.post("/mint", response_model=NFT)
async def mint_nft(req: MintRequest):
    """Calling the blockchain to mint a new NFT"""
    wallet = SuiWallet()  # Load wallet for signing
    signer = SignerWithProvider(wallet, provider)

    # Execute Move call
    result = await signer.execute_move_call(
        package_id=PACKAGE_ID,
        module=MODULE_NAME,
        function="mint_nft",
        type_arguments=[],
        arguments=[]
    )

    # Extract created object ID
    nft_id = result["effects"]["created"][0]["objectId"]
    nft = NFT(id=nft_id, name=req.name, owner=req.owner)
    return nft


@app.post("/list", response_model=Listing)
async def list_nft(req: ListRequest):
    wallet = SuiWallet()  
    signer = SignerWithProvider(wallet, provider)

    result = await signer.execute_move_call(
        package_id=PACKAGE_ID,
        module=MODULE_NAME,
        function="list_nft",
        type_arguments=[],
        arguments=[req.nft_id, req.price]
    )

    listing = Listing(
        id=req.nft_id,
        nft=NFT(id=req.nft_id, name="Unknown", owner=req.seller),
        price=req.price,
        seller=req.seller
    )
    return listing


@app.post("/buy", response_model=Listing)
async def buy_nft(req: BuyRequest):
    """Calling the blockchain to buy a listed NFT"""
    wallet = SuiWallet()  
    signer = SignerWithProvider(wallet, provider)

    result = await signer.execute_move_call(
        package_id=PACKAGE_ID,
        module=MODULE_NAME,
        function="buy",
        type_arguments=[],
        arguments=[req.listing_id, req.payment_id]
    )

    listing = Listing(
        id=req.listing_id,
        nft=NFT(id=req.listing_id, name="Unknown", owner=req.buyer),
        price=0, 
        seller="Unknown"
    )
    return listing


@app.get("/listings", response_model=List[Listing])
def get_listings():
    """Fetch live listings from the blockchain - not implemented yet"""
    raise HTTPException(status_code=501, detail="Fetching live listings not implemented")
