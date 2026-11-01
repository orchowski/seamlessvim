import spock.lang.Specification

class AdderSpec extends Specification {
    def "adds two numbers"() {
        expect:
        2 + 3 == 5
    }
}
