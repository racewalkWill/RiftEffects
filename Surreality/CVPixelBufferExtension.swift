/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import AVFoundation
import UIKit
import Accelerate
// review the Accelerate docuementation
// this is a CG (Core Graphics) oriented set of vector functions to operate
// on image formats
// mostly it operates from a source buffer to a target buffer of bytes that then
// are output as a CGImage. See workFlow documentation in Accelerate/vImage

extension CVPixelBuffer {
  func normalize() {
    let width = CVPixelBufferGetWidth(self)
    let height = CVPixelBufferGetHeight(self)
    
    CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
    let pixelBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(self), to: UnsafeMutablePointer<Float>.self)

    // MARK: TO_DO
    var minPixel: Float = 1.0  // change to Float16 in Swift 5.3 (Xcode 12, currently in beta 2020-09-12)
    var maxPixel: Float = 0.0
    
    /// You might be wondering why the for loops below use `stride(from:to:step:)`
    /// instead of a simple `Range` such as `0 ..< height`?
    /// The answer is because in Swift 5.1, the iteration of ranges performs badly when the
    /// compiler optimisation level (`SWIFT_OPTIMIZATION_LEVEL`) is set to `-Onone`,
    /// which is eactly what happens when running this sample project in Debug mode.
    /// If this was a production app then it might not be worth worrying about but it is still
    /// worth being aware of.
    
    for y in stride(from: 0, to: height, by: 1) {
      for x in stride(from: 0, to: width, by: 1) {
        let pixel = pixelBuffer[y * width + x]
        minPixel = min(pixel, minPixel)
        maxPixel = max(pixel, maxPixel)
      }
    }
    
    let range = maxPixel - minPixel
    NSLog("CVPixelBuffer #normalize start maxPixel = \(maxPixel), min = \(minPixel) range = \(range)")
    for y in stride(from: 0, to: height, by: 1) {
      for x in stride(from: 0, to: width, by: 1) {
        let pixel = pixelBuffer[y * width + x]
        pixelBuffer[y * width + x] = (pixel - minPixel) / range
      }
    }

 // check for new values
     minPixel = 1.0
     maxPixel = 0.0
    for y in stride(from: 0, to: height, by: 1) {
      for x in stride(from: 0, to: width, by: 1) {
        let pixel = pixelBuffer[y * width + x]
        minPixel = min(pixel, minPixel)
        maxPixel = max(pixel, maxPixel)
      }
    }
    let newRange = maxPixel - minPixel
     NSLog("CVPixelBuffer #normalize finish maxPixel = \(maxPixel), min = \(minPixel) range = \(newRange)")


    CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))

  }

    func setUpNormalize() -> CVPixelBuffer {
        // grayscale buffer float16
        // return new normalized CVPixelBuffer
        let pixelBuffer = self
        CVPixelBufferLockBaseAddress(pixelBuffer,
                                     CVPixelBufferLockFlags.readOnly)
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let count = width * height

        let lumaBaseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)
        let lumaRowBytes = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)

        let lumaCopy = UnsafeMutableRawPointer.allocate(byteCount: count,
                                                        alignment: MemoryLayout<Pixel_16U>.alignment)
        lumaCopy.copyMemory(from: lumaBaseAddress!,
                            byteCount: count)


        CVPixelBufferUnlockBaseAddress(pixelBuffer,
                                       CVPixelBufferLockFlags.readOnly)
//        DispatchQueue.global(qos: .utility).async {
          let newBuffer =   self.processImage(data: lumaCopy,
                              rowBytes: lumaRowBytes,
                              width: width,
                              height: height )

            lumaCopy.deallocate()
//        } queue .async block
        return newBuffer

    }

func processImage(data: UnsafeMutableRawPointer,
                      rowBytes: Int,
                      width: Int, height: Int) -> CVPixelBuffer {
        // use the Accelerate vDSP_normalize demo in the
        // Accelerate Blur Detection sample app
        // need to combine and simply the photoOutput function and the processImage function
        // below is mixed.. redo.
        //


        var sourceBuffer = vImage_Buffer(data: data,
                                         height: vImagePixelCount(height),
                                         width: vImagePixelCount(width),
                                         rowBytes: rowBytes)
        var floatPixels: [Float]
        let count = width * height
//        if sourceBuffer.rowBytes == width * MemoryLayout<Pixel_16S>.stride {
//            let start = sourceBuffer.data.assumingMemoryBound(to: Pixel_16S.self)
//            floatPixels = vDSP.integerToFloatingPoint(
//                UnsafeMutableBufferPointer(start: start,
//                                           count: count),
//                floatingPointType: Float.self)
//        } else {
            floatPixels = [Float](unsafeUninitializedCapacity: count) {
                buffer, initializedCount in

                var floatBuffer = vImage_Buffer(data: buffer.baseAddress,
                                                height: sourceBuffer.height,
                                                width: sourceBuffer.width,
                                                rowBytes: width * MemoryLayout<Float16>.size)
                // need to copy memory from the data into the floatPixels
//              vImageConvert_Planar8toPlanarF(&sourceBuffer,  &floatBuffer ,0, 1, vImage_Flags(kvImageNoFlags))
                let floatBaseAddress = floatBuffer.data
                if let copyReturnValue = try? sourceBuffer.copy(destinationBuffer: &floatBuffer, pixelSize: MemoryLayout<Float16>.size)
                    { NSLog("CVPixelBuffer #processImage memory copy returns \(copyReturnValue)") }
                else { fatalError("CVPixelBuffer #processImage memory copy failed")}


                initializedCount = count
            }
//        }


//         Calculate standard deviation.
               var mean = Float.nan
               var stdDev = Float.nan
        // modify self: CVPixelBuffer
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        let pixelBufferBase  = unsafeBitCast(CVPixelBufferGetBaseAddress(self), to: UnsafeMutablePointer<Float>.self)
    // normalize to a 0..1 range in self (cvPixelBuffer).
        vDSP_normalize(floatPixels, 1,
                       pixelBufferBase, 1,
                       &mean, &stdDev,
                       vDSP_Length(count))

    CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
    }
}
