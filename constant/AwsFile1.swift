//
//  AwsFile1.swift
//  SkromanIsra
//
//  Created by Admin on 18/01/25.
//

import Foundation
import AWSCore


let CertificateSigningRequestCommonName = "Skroman iOS Slide Series"
let CertificateSigningRequestCountryName = "India"
let CertificateSigningRequestOrganizationName = "Skroman"
let CertificateSigningRequestOrganizationalUnitName = "Skroman R&D"

let POLICY_NAME = "Abcd_Policy"

// This is the endpoint in your AWS IoT console. eg: https://xxxxxxxxxx.iot.<region>.amazonaws.com
let AWS_REGION = AWSRegionType.APSouth1

//For both connecting over websockets and cert, IOT_ENDPOINT should look like
//https://xxxxxxx-ats.iot.REGION.amazonaws.com


let IOT_ENDPOINT = "https://a2n4hdipq41ly9-ats.iot.ap-south-1.amazonaws.com"
let IDENTITY_POOL_ID = "ap-south-1:e895760d-a7a8-4de7-9245-66d0f2e9af34"

//Used as keys to look up a reference of each manager
let AWS_IOT_DATA_MANAGER_KEY = "MyIotDataManager"
let AWS_IOT_MANAGER_KEY = "MyIotManager"

