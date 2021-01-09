//
//  CompositeOverBlackFilter.swift
//  Filterpedia
//
//  Created by Simon Gladman on 01/01/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//
// Simon uses this permission language in Filterpedia
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>

import UIKit
import CoreImage

class CompositeOverBlackFilter: CIFilter
{
    let black: CIFilter
    let composite: CIFilter
    
    @objc var inputImage : CIImage?
    
    override init()
    {
        black = CIFilter(name: "CIConstantColorGenerator",
                         parameters: [kCIInputColorKey: CIColor(color: UIColor.lightGray)])!
        
        composite = CIFilter(name: "CISourceAtopCompositing",
                             parameters: [kCIInputBackgroundImageKey: black.outputImage!])!
        
        super.init()
    }

    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var outputImage: CIImage!
    {
        guard let inputImage = inputImage else
        {
            return nil
        }
        
        composite.setValue(inputImage, forKey: kCIInputImageKey)
        
        return composite.outputImage
    }
}
