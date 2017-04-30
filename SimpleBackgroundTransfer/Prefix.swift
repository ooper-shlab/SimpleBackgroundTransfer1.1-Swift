//
//  Prefix.swift
//  SimpleBackgroundTransfer
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/3/21.
//
//

//
//  Prefix header
//
//  The contents of this file are implicitly included at the beginning of every source file.
//

import Foundation


func BLog(_ function: String = #function, format formatString: String = "", args: CVarArg...) {
    NSLog("\(function) %@", String(format: formatString, arguments: args))
}
