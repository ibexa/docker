// Custom parameters.vcl for docker use

backend ezplatform {
    .host = "web";
    .port = "80";
}

// ACL for invalidators IP
acl invalidators {
    "127.0.0.1";
    "172.16.0.0"/12;
// ACL_INVALIDATOR
}

// ACL for debuggers IP
acl debuggers {
    "127.0.0.1";
    "172.16.0.0"/12;
// DEBUGGER
}

// ACL for reverse proxies, TLS terminators and CDNs running in front of Varnish
//
// Only these are allowed to set the "X-Forwarded-*" and "Forwarded" headers, see vcl_recv.
// Deliberately does not include the Docker network segment: nothing runs in front of Varnish in
// this setup, so every incoming request is to be treated as coming straight from a client.
// Extend with --trusted-proxy-add if you put something in front of it.
acl trusted_proxies {
    "127.0.0.1";
// TRUSTED_PROXY
}
