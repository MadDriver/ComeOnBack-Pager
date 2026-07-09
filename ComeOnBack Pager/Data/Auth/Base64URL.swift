//
//  Base64URL.swift
//  ComeOnBack Pager
//
//  base64url (RFC 4648 §5) helpers shared by the PKCE challenge derivation and the
//  JWT payload decode. base64url is plain base64 with `+`→`-`, `/`→`_`, and no `=`
//  padding — the encoding OAuth/JWT use so tokens are URL- and header-safe.
//

import Foundation

extension Data {
    /// Encode as base64url with padding stripped.
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// Decode a base64url string, restoring the padding base64 needs. Returns nil
    /// for anything that isn't valid base64url.
    init?(base64URLEncoded input: String) {
        var s = input
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while s.count % 4 != 0 { s.append("=") }
        self.init(base64Encoded: s)
    }
}
