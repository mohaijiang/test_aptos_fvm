// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

  struct RequestId {
    bytes32 requestId;
    bool valid;
  }

  struct RequestIdx {
    uint256 idx;
    bool valid;
  }

  struct ProviderSet {
    bytes provider;
    bool valid;
  }

  struct DealRequest {
    bytes piece_cid;
    uint64 piece_size;
    bool verified_deal;
    string label;
    int64 start_epoch;
    int64 end_epoch;
    uint256 storage_price_per_epoch;
    uint256 provider_collateral;
    uint256 client_collateral;
    uint64 extra_params_version;
    ExtraParamsV1 extra_params;
  }

  struct ExtraParamsV1 {
    string location_ref;
    uint64 car_size;
    bool skip_ipni_announce;
    bool remove_unsealed_copy;
  }

contract test {
  enum Status {
    None,
    RequestSubmitted,
    DealPublished,
    DealActivated,
    DealTerminated
  }

  mapping(bytes32 => RequestIdx) public dealRequestIdx;
  DealRequest[] public dealRequests;

  mapping(bytes => RequestId) public pieceRequests;
  mapping(bytes => ProviderSet) public pieceProviders;
  mapping(bytes => uint64) public pieceDeals;
  mapping(bytes => Status) public pieceStatus;

  event DealProposalCreate(
    bytes32 indexed id,
    uint64 size,
    bool indexed verified,
    uint256 price
  );

  address public owner;

  constructor() {
    owner = msg.sender;
  }

  function getProviderSet(
    bytes calldata cid
  ) public view returns (ProviderSet memory) {
    return pieceProviders[cid];
  }

  function getProposalIdSet(
    bytes calldata cid
  ) public view returns (RequestId memory) {
    return pieceRequests[cid];
  }

  function dealsLength() public view returns (uint256) {
    return dealRequests.length;
  }

  function getDealByIndex(
    uint256 index
  ) public view returns (DealRequest memory) {
    return dealRequests[index];
  }

  function makeDealProposal(
    DealRequest calldata deal
  ) public returns (bytes32) {
    require(msg.sender == owner);

    if (pieceStatus[deal.piece_cid] == Status.DealPublished ||
      pieceStatus[deal.piece_cid] == Status.DealActivated) {
      revert("deal with this pieceCid already published");
    }

    uint256 index = dealRequests.length;
    dealRequests.push(deal);

    bytes32 id = keccak256(
      abi.encodePacked(block.timestamp, msg.sender, index)
    );
    dealRequestIdx[id] = RequestIdx(index, true);

    pieceRequests[deal.piece_cid] = RequestId(id, true);
    pieceStatus[deal.piece_cid] = Status.RequestSubmitted;

    emit DealProposalCreate(
      id,
      deal.piece_size,
      deal.verified_deal,
      deal.storage_price_per_epoch
    );

    return id;
  }

}
