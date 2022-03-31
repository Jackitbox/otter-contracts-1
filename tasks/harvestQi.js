const { task, types } = require('hardhat/config')

const QI_LOCKER = '0x69f6c4Fa150F9F0b3037612CF8FadDAeDbd46Bb8'
const OC_QI = '0x0906ee253B2cD6737A3CD3838490Cb0b90fD68be'
const EQI = '0x880decade22ad9c58a8a4202ef143c4f305100b3'

task('harvestQi', 'Harvest airdrop Qi')
  .addPositionalParam('relock', '', false, types.boolean)
  .setAction(async ({ relock }, { ethers }) => {
    const qiLocker = await ethers.getContractAt('OtterQiLocker', QI_LOCKER)
    const ocQi = await ethers.getContractAt('OtterClamQi', OC_QI)
    const eQi = await ethers.getContractAt('EQi', EQI)

    const lockedInfo = await eQi.userInfo(ocQi.address)
    console.log('locked amount: ', lockedInfo.amount)
    console.log('locked end block: ', lockedInfo.endBlock)

    const blockNumber = await ethers.provider.getBlockNumber()
    const maxLock = await ocQi.maxLock()
    const extendedLockNumber = relock
      ? maxLock.add(blockNumber).sub(lockedInfo.endBlock)
      : 0

    const tx = await qiLocker.harvest(extendedLockNumber)
    console.log('harvest & extend lock: ' + extendedLockNumber)
    console.log('tx: ', tx.hash)
    await tx.wait()
    console.log('done')
  })
