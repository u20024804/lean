/*
Copyright (c) 2014 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Author: Leonardo de Moura
*/
#include "library/num.h"
#include "library/util.h"
#include "library/constants.h"

namespace lean {
bool is_const_app(expr const & e, name const & n, unsigned nargs) {
    expr const & f = get_app_fn(e);
    return is_constant(f) && const_name(f) == n && get_app_num_args(e) == nargs;
}

bool is_zero(expr const & e) {
    return
        is_const_app(e, get_zero_name(), 2) ||
        is_constant(e, get_nat_zero_name());
}

bool is_one(expr const & e) {
    return
        is_const_app(e, get_one_name(), 2) ||
        (is_const_app(e, get_nat_succ_name(), 1) && is_zero(app_arg(e)));
}

optional<expr> is_bit0(expr const & e) {
    if (!is_const_app(e, get_bit0_name(), 3))
        return none_expr();
    return some_expr(app_arg(e));
}

optional<expr> is_bit1(expr const & e) {
    if (!is_const_app(e, get_bit1_name(), 4))
        return none_expr();
    return some_expr(app_arg(e));
}

optional<expr> is_neg(expr const & e) {
    if (!is_const_app(e, get_neg_name(), 3))
        return none_expr();
    return some_expr(app_arg(e));
}

optional<expr> unfold_num_app(environment const & env, expr const & e) {
    if (is_zero(e) || is_one(e) || is_bit0(e) || is_bit1(e)) {
        return unfold_app(env, e);
    } else {
        return none_expr();
    }
}

bool is_numeral_const_name(name const & n) {
    return n == get_zero_name() || n == get_one_name() || n == get_bit0_name() || n == get_bit1_name();
}

static bool is_num(expr const & e, bool first) {
    if (is_zero(e))
        return first;
    else if (is_one(e))
        return true;
    else if (auto a = is_bit0(e))
        return is_num(*a, false);
    else if (auto a = is_bit1(e))
        return is_num(*a, false);
    else
        return false;
}

bool is_num(expr const & e) {
    return is_num(e, true);
}

bool is_signed_num(expr const & e) {
    if (is_num(e))
        return true;
    else if (auto r = is_neg(e))
        return is_num(*r);
    else
        return false;
}

static optional<mpz> to_num(expr const & e, bool first) {
    if (is_zero(e)) {
        return first ? some(mpz(0)) : optional<mpz>();
    } else if (is_one(e)) {
        return some(mpz(1));
    } else if (auto a = is_bit0(e)) {
        if (auto r = to_num(*a, false))
            return some(2*(*r));
    } else if (auto a = is_bit1(e)) {
        if (auto r = to_num(*a, false))
            return some(2*(*r)+1);
    } else if (auto a = is_neg(e)) {
        if (auto r = to_num(*a, false))
            return some(neg(*r));
    }
    return optional<mpz>();
}

optional<mpz> to_num(expr const & e) {
    return to_num(e, true);
}

optional<mpz> to_pos_num(expr const & e) {
    if (is_constant(e, get_pos_num_one_name())) {
         return some(mpz(1));
    } else if (is_const_app(e, get_pos_num_bit0_name(), 1)) {
        if (auto r = to_pos_num(app_arg(e)))
            return some(2*(*r));
    } else if (is_const_app(e, get_pos_num_bit1_name(), 1)) {
        if (auto r = to_pos_num(app_arg(e)))
            return some(2*(*r) + 1);
    }
    return optional<mpz>();
}

optional<mpz> to_num_core(expr const & e) {
    if (is_constant(e, get_num_zero_name()))
        return some(mpz(0));
    else if (is_const_app(e, get_num_pos_name(), 1))
        return to_pos_num(app_arg(e));
    else
        return optional<mpz>();
}

bool is_num_leaf_constant(name const & n) {
    return
        n == get_zero_name() ||
        n == get_one_name() ||
        n == get_has_zero_zero_name() ||
        n == get_has_one_one_name();
}

expr to_nat_expr_core(mpz const & n) {
    lean_assert(n >= 0);
    if (n == 1)
        return mk_nat_one();
    else if (n % mpz(2) == 0)
        return mk_nat_bit0(to_nat_expr(n / 2));
    else
        return mk_nat_bit1(to_nat_expr(n / 2));
}

expr to_nat_expr(mpz const & n) {
    if (n == 0)
        return mk_nat_zero();
    else
        return to_nat_expr_core(n);
}

void initialize_num() {}
void finalize_num() {}
}
