pragma solidity ^0.4.24;

import "./SafeMath.sol";

contract RNGCore {

  using SafeMath for uint;

  uint256[] private queuedBlocks;
  mapping(uint256 => bool) private blockRoster;
  mapping(uint256 => bytes32) private hashes;
  mapping(uint256 => uint256) private rngSeeds;
  uint256 private nonce;

  event BlockQueued(uint256 block);
  event BlockStored(uint256 block);

  function nextSeed() public returns (uint256) {

    uint256 nextBlock = block.number.add(3);

    setBlockhash();

    if (blockRoster[nextBlock] == false) {

      blockRoster[nextBlock] = true;
      queuedBlocks.push(nextBlock);
      emit BlockQueued(nextBlock);
    }

    return nextBlock;
  }

  function nextRNG(uint256 _block) public returns (uint256) {

    uint256 rng = uint256(keccak256(abi.encodePacked(block.number, rngSeeds[_block], nonce)));
    nonce = nonce.add(1);

    rngSeeds[_block] = rng;
    return rng;
  }

  function setBlockhash() private {

    uint256 blok;
    uint256 processedBlockCount = 0;
    uint256 currentBlockMinus256 = block.number;
    bool adjustQueue = false;
    uint256 newLength;

    if (currentBlockMinus256 < 256) {
      currentBlockMinus256 = 0;
    } else {
      currentBlockMinus256 = currentBlockMinus256.sub(256);
    }

    for (uint256 i = 0; i < queuedBlocks.length; i++) {

      blok = queuedBlocks[i];

      if (blok < block.number) {

        if (blok >= currentBlockMinus256) {

          hashes[blok] = blockhash(blok);
          rngSeeds[blok] = uint256(hashes[blok]);
          emit BlockStored(blok);
        }

        blockRoster[blok] = false;
        processedBlockCount = processedBlockCount.add(1);
        adjustQueue = true;
      }
    }

    if (!adjustQueue) { return; }

    newLength = queuedBlocks.length.sub(processedBlockCount);

    for (i = 0; i < newLength; i++) {
      queuedBlocks[i] = queuedBlocks[i.add(processedBlockCount)];
    }

    queuedBlocks.length = newLength;
  }

  function getBool(uint256 _block) public view returns (bool) {
    return uint256(getHash(_block)).mod(2) == 0;
  }

  function getHash(uint256 _block) private view returns (bytes32) {

    if (hashes[_block] == 0x0) { return; }

    return hashes[_block];
  }

  function getUint(uint256 _block) public view returns (uint256) {
    return uint256(getHash(_block));
  }

  function getXORHash(bytes32 _a, bytes32 _b) public pure returns (bytes32) {

    bytes32 resultHash = 0x0;

    assembly {
      resultHash:= xor(_a, _b)
    }

    return resultHash;
  }
}
