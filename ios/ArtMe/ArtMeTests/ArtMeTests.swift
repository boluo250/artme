//
//  ArtMeTests.swift
//  ArtMeTests
//
//  单元测试
//

import XCTest
@testable import ArtMe

final class ArtMeTests: XCTestCase {
    
    func testConstants() {
        XCTAssertFalse(Constants.apiBaseURL.isEmpty)
        XCTAssertFalse(Constants.API.generate.isEmpty)
    }
    
    func testStyleModel() {
        let style = Style(
            id: "test_001",
            name: "Test Style",
            description: "Test Description",
            category: "test",
            exampleImageUrl: "/test.jpg",
            promptTemplate: "test {user_prompt}",
            tags: ["test"]
        )
        
        XCTAssertEqual(style.id, "test_001")
        XCTAssertEqual(style.name, "Test Style")
    }
    
    func testGenerateImageRequest() {
        let request = GenerateImageRequest(
            prompt: "test prompt",
            styleId: "style_001",
            width: 512,
            height: 512
        )
        
        XCTAssertEqual(request.prompt, "test prompt")
        XCTAssertEqual(request.styleId, "style_001")
        XCTAssertEqual(request.width, 512)
    }
}

