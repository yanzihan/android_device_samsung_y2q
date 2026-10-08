/*
 * Restores android::base::Trim(std::string const&) for the stock NXP NFC blobs.
 *
 * nfc_nci_nxpsn.so (and ese_spi_nxp.so) are prebuilts from a tree where libbase
 * still exported the non-template overload
 *
 *     std::string android::base::Trim(const std::string&);
 *
 * mangled as
 *
 *     _ZN7android4base4TrimERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE
 *
 * Android 14 removed that overload in favour of templates, so the libbase in this
 * tree exports only Trim<T>(...) instantiations and nothing matches that name.  The
 * build-time check was silenced with allow_undefined_symbols on the
 * nfc_nci_nxpsn / ese_spi_nxp modules, but that only affects verification: at
 * runtime the dynamic linker still cannot resolve the symbol and the HAL dies
 * before it starts:
 *
 *     CANNOT LINK EXECUTABLE "/vendor/bin/hw/nxp.android.hardware.nfc@1.2-service":
 *       cannot locate symbol "_ZN7android4base4TrimERKNSt3__1...E"
 *       referenced by "/vendor/lib64/nfc_nci_nxpsn.so"
 *
 * so init never registers vendor.nfc_hal_service and NFC cannot be switched on.
 *
 * The symbol name is specified explicitly with an asm label rather than relying on
 * the compiler to mangle a matching C++ signature.  Writing the signature
 * correctly would depend on the target's standard library ABI (libc++ wraps
 * everything in std::__1 with a custom allocator, unlike libstdc++), and a name
 * that is even slightly off is silently useless at runtime.  Spelling the mangled
 * name out removes that whole class of mistake.
 *
 * The body trims ASCII whitespace from both ends, as the removed implementation
 * did.  It is a strong definition, so it takes precedence over the weak template
 * instantiations libbase also provides.
 */

#include <string>

// std::string android::base::Trim(std::string const&)
std::string trim_for_legacy_nfc(const std::string& s)
    __asm__("_ZN7android4base4TrimERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");

std::string trim_for_legacy_nfc(const std::string& s) {
    static const char kWhitespace[] = " \t\n\v\f\r";

    const std::string::size_type begin = s.find_first_not_of(kWhitespace);
    if (begin == std::string::npos) {
        return std::string();
    }
    const std::string::size_type end = s.find_last_not_of(kWhitespace);
    return s.substr(begin, end - begin + 1);
}
