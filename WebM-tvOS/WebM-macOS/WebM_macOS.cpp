//
//  WebM_macOS.cpp
//  WebM-macOS
//
//  Created by Alex Pecoraro on 7/13/20.
//  Copyright © 2020 Rainway Inc. All rights reserved.
//

#include <iostream>
#include "WebM_macOS.hpp"
#include "WebM_macOSPriv.hpp"

void WebM_macOS::HelloWorld(const char * s)
{
    WebM_macOSPriv *theObj = new WebM_macOSPriv;
    theObj->HelloWorldPriv(s);
    delete theObj;
};

void WebM_macOSPriv::HelloWorldPriv(const char * s) 
{
    std::cout << s << std::endl;
};

