//
//  Style.swift
//  ArtMe
//
//  风格模型
//

import Foundation

struct Style: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let category: String
    let exampleImageUrl: String
    let promptTemplate: String
    let tags: [String]
}

struct StyleListResponse: Codable {
    let styles: [Style]
    let total: Int
}

