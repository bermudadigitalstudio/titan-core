/// Little known fact: HTTP headers need not be unique!
public typealias Header = (String, String)

public protocol RequestType {
    var body: String { get set }
    var path: String { get set }
    var method: String { get set }
    var headers: [Header] { get set }
}

public protocol ResponseType {
    var body: String { get set }
    /// Status code. We have deliberately eschewed a status line since HTTP/2 ignores it, rarely used.
    var code: Int { get set }
    var headers: [Header] { get set }
}

public struct Request {
    public var method: String
    public var path: String
    public var body: String
    public var headers: [Header]

    public init(_ method: String, _ path: String, _ body: String = "", headers: [Header] = []) {
        self.method = method
        self.path = path
        self.body = body
        self.headers = headers
    }
}

public struct Response {
    public var code: Int
    public var body: String
    public var headers: [Header]

    public init(_ code: Int, _ body: String, headers: [Header] = []) {
        self.code = code
        self.body = body
        self.headers = headers
    }
}

extension Response: ResponseType {}

extension Request: RequestType {}

public typealias Middleware = (inout RequestType, inout ResponseType) -> (RequestType, ResponseType)
public final class Titan {
    public init() {}
    private var middlewareStack = Array<Middleware>()
    public func middleware(_ middleware: @escaping Middleware) {
        middlewareStack.append(middleware)
    }
    public func app(request: RequestType) -> ResponseType {
        typealias Result = (RequestType, ResponseType)
        let initialReq = request
        let initialRes = Response(-1, "")
        let initial: Result = (initialReq, initialRes)
        let res = middlewareStack.reduce(initial) { (res, next) -> Result in
            var mutableRes = res
            return next(&mutableRes.0, &mutableRes.1)
        }
        return res.1
    }
}
