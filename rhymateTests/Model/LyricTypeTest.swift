import Testing
@testable import rhymate

struct LyricTypeTest {

    @Test func testFromString() async throws {
        struct TestData {
        let text: String
        let expected: LyricType
        }
        let testData: [TestData] = [
            TestData(text: "test", expected: .word),
            TestData(text: "This is a phrase", expected: .phrase),
            TestData(text: "", expected: .none)
        ]
        
        for data in testData {
            let result = LyricType.from(data.text)
            #expect(data.expected == result)
        }
    }

}
