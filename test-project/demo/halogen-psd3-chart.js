// output/Demo.HalogenPSD3Chart/foreign.js
var parseDataMessageImpl = (msg) => {
  try {
    const data = JSON.parse(msg);
    if (data.type === "data" && data.values) {
      return {
        tick: data.tick,
        time: data.time,
        primary: data.values.primary,
        secondary: data.values.secondary
      };
    }
    return null;
  } catch (e) {
    return null;
  }
};

// output/Control.Apply/foreign.js
var arrayApply = function(fs) {
  return function(xs) {
    var l = fs.length;
    var k = xs.length;
    var result = new Array(l * k);
    var n = 0;
    for (var i2 = 0; i2 < l; i2++) {
      var f = fs[i2];
      for (var j = 0; j < k; j++) {
        result[n++] = f(xs[j]);
      }
    }
    return result;
  };
};

// output/Control.Semigroupoid/index.js
var semigroupoidFn = {
  compose: function(f) {
    return function(g) {
      return function(x4) {
        return f(g(x4));
      };
    };
  }
};

// output/Control.Category/index.js
var identity = function(dict) {
  return dict.identity;
};
var categoryFn = {
  identity: function(x4) {
    return x4;
  },
  Semigroupoid0: function() {
    return semigroupoidFn;
  }
};

// output/Data.Boolean/index.js
var otherwise = true;

// output/Data.Function/index.js
var flip = function(f) {
  return function(b10) {
    return function(a2) {
      return f(a2)(b10);
    };
  };
};
var $$const = function(a2) {
  return function(v) {
    return a2;
  };
};

// output/Data.Functor/foreign.js
var arrayMap = function(f) {
  return function(arr) {
    var l = arr.length;
    var result = new Array(l);
    for (var i2 = 0; i2 < l; i2++) {
      result[i2] = f(arr[i2]);
    }
    return result;
  };
};

// output/Data.Unit/foreign.js
var unit = void 0;

// output/Data.Functor/index.js
var map = function(dict) {
  return dict.map;
};
var mapFlipped = function(dictFunctor) {
  var map111 = map(dictFunctor);
  return function(fa) {
    return function(f) {
      return map111(f)(fa);
    };
  };
};
var $$void = function(dictFunctor) {
  return map(dictFunctor)($$const(unit));
};
var voidLeft = function(dictFunctor) {
  var map111 = map(dictFunctor);
  return function(f) {
    return function(x4) {
      return map111($$const(x4))(f);
    };
  };
};
var functorArray = {
  map: arrayMap
};

// output/Control.Apply/index.js
var identity2 = /* @__PURE__ */ identity(categoryFn);
var applyArray = {
  apply: arrayApply,
  Functor0: function() {
    return functorArray;
  }
};
var apply = function(dict) {
  return dict.apply;
};
var applySecond = function(dictApply) {
  var apply1 = apply(dictApply);
  var map23 = map(dictApply.Functor0());
  return function(a2) {
    return function(b10) {
      return apply1(map23($$const(identity2))(a2))(b10);
    };
  };
};

// output/Control.Applicative/index.js
var pure = function(dict) {
  return dict.pure;
};
var unless = function(dictApplicative) {
  var pure14 = pure(dictApplicative);
  return function(v) {
    return function(v1) {
      if (!v) {
        return v1;
      }
      ;
      if (v) {
        return pure14(unit);
      }
      ;
      throw new Error("Failed pattern match at Control.Applicative (line 68, column 1 - line 68, column 65): " + [v.constructor.name, v1.constructor.name]);
    };
  };
};
var when = function(dictApplicative) {
  var pure14 = pure(dictApplicative);
  return function(v) {
    return function(v1) {
      if (v) {
        return v1;
      }
      ;
      if (!v) {
        return pure14(unit);
      }
      ;
      throw new Error("Failed pattern match at Control.Applicative (line 63, column 1 - line 63, column 63): " + [v.constructor.name, v1.constructor.name]);
    };
  };
};
var liftA1 = function(dictApplicative) {
  var apply2 = apply(dictApplicative.Apply0());
  var pure14 = pure(dictApplicative);
  return function(f) {
    return function(a2) {
      return apply2(pure14(f))(a2);
    };
  };
};

// output/Control.Bind/foreign.js
var arrayBind = function(arr) {
  return function(f) {
    var result = [];
    for (var i2 = 0, l = arr.length; i2 < l; i2++) {
      Array.prototype.push.apply(result, f(arr[i2]));
    }
    return result;
  };
};

// output/Control.Bind/index.js
var identity3 = /* @__PURE__ */ identity(categoryFn);
var discard = function(dict) {
  return dict.discard;
};
var bindArray = {
  bind: arrayBind,
  Apply0: function() {
    return applyArray;
  }
};
var bind = function(dict) {
  return dict.bind;
};
var bindFlipped = function(dictBind) {
  return flip(bind(dictBind));
};
var composeKleisliFlipped = function(dictBind) {
  var bindFlipped12 = bindFlipped(dictBind);
  return function(f) {
    return function(g) {
      return function(a2) {
        return bindFlipped12(f)(g(a2));
      };
    };
  };
};
var discardUnit = {
  discard: function(dictBind) {
    return bind(dictBind);
  }
};
var join = function(dictBind) {
  var bind16 = bind(dictBind);
  return function(m) {
    return bind16(m)(identity3);
  };
};

// output/Data.Bounded/foreign.js
var topChar = String.fromCharCode(65535);
var bottomChar = String.fromCharCode(0);
var topNumber = Number.POSITIVE_INFINITY;
var bottomNumber = Number.NEGATIVE_INFINITY;

// output/Data.Ord/foreign.js
var unsafeCompareImpl = function(lt2) {
  return function(eq3) {
    return function(gt2) {
      return function(x4) {
        return function(y4) {
          return x4 < y4 ? lt2 : x4 === y4 ? eq3 : gt2;
        };
      };
    };
  };
};
var ordIntImpl = unsafeCompareImpl;
var ordStringImpl = unsafeCompareImpl;

// output/Data.Eq/foreign.js
var refEq = function(r1) {
  return function(r2) {
    return r1 === r2;
  };
};
var eqIntImpl = refEq;
var eqStringImpl = refEq;

// output/Data.Eq/index.js
var eqUnit = {
  eq: function(v) {
    return function(v1) {
      return true;
    };
  }
};
var eqString = {
  eq: eqStringImpl
};
var eqInt = {
  eq: eqIntImpl
};
var eq = function(dict) {
  return dict.eq;
};

// output/Data.Ordering/index.js
var LT = /* @__PURE__ */ (function() {
  function LT2() {
  }
  ;
  LT2.value = new LT2();
  return LT2;
})();
var GT = /* @__PURE__ */ (function() {
  function GT2() {
  }
  ;
  GT2.value = new GT2();
  return GT2;
})();
var EQ = /* @__PURE__ */ (function() {
  function EQ2() {
  }
  ;
  EQ2.value = new EQ2();
  return EQ2;
})();

// output/Data.Ring/foreign.js
var intSub = function(x4) {
  return function(y4) {
    return x4 - y4 | 0;
  };
};

// output/Data.Semiring/foreign.js
var intAdd = function(x4) {
  return function(y4) {
    return x4 + y4 | 0;
  };
};
var intMul = function(x4) {
  return function(y4) {
    return x4 * y4 | 0;
  };
};

// output/Data.Semiring/index.js
var semiringInt = {
  add: intAdd,
  zero: 0,
  mul: intMul,
  one: 1
};

// output/Data.Ring/index.js
var ringInt = {
  sub: intSub,
  Semiring0: function() {
    return semiringInt;
  }
};

// output/Data.Ord/index.js
var ordUnit = {
  compare: function(v) {
    return function(v1) {
      return EQ.value;
    };
  },
  Eq0: function() {
    return eqUnit;
  }
};
var ordString = /* @__PURE__ */ (function() {
  return {
    compare: ordStringImpl(LT.value)(EQ.value)(GT.value),
    Eq0: function() {
      return eqString;
    }
  };
})();
var ordInt = /* @__PURE__ */ (function() {
  return {
    compare: ordIntImpl(LT.value)(EQ.value)(GT.value),
    Eq0: function() {
      return eqInt;
    }
  };
})();
var compare = function(dict) {
  return dict.compare;
};
var max = function(dictOrd) {
  var compare3 = compare(dictOrd);
  return function(x4) {
    return function(y4) {
      var v = compare3(x4)(y4);
      if (v instanceof LT) {
        return y4;
      }
      ;
      if (v instanceof EQ) {
        return x4;
      }
      ;
      if (v instanceof GT) {
        return x4;
      }
      ;
      throw new Error("Failed pattern match at Data.Ord (line 181, column 3 - line 184, column 12): " + [v.constructor.name]);
    };
  };
};

// output/Data.Show/foreign.js
var showIntImpl = function(n) {
  return n.toString();
};
var showNumberImpl = function(n) {
  var str2 = n.toString();
  return isNaN(str2 + ".0") ? str2 : str2 + ".0";
};

// output/Data.Show/index.js
var showNumber = {
  show: showNumberImpl
};
var showInt = {
  show: showIntImpl
};
var showBoolean = {
  show: function(v) {
    if (v) {
      return "true";
    }
    ;
    if (!v) {
      return "false";
    }
    ;
    throw new Error("Failed pattern match at Data.Show (line 29, column 1 - line 31, column 23): " + [v.constructor.name]);
  }
};
var show = function(dict) {
  return dict.show;
};

// output/Data.HeytingAlgebra/foreign.js
var boolConj = function(b12) {
  return function(b22) {
    return b12 && b22;
  };
};
var boolDisj = function(b12) {
  return function(b22) {
    return b12 || b22;
  };
};
var boolNot = function(b10) {
  return !b10;
};

// output/Data.HeytingAlgebra/index.js
var tt = function(dict) {
  return dict.tt;
};
var not = function(dict) {
  return dict.not;
};
var implies = function(dict) {
  return dict.implies;
};
var ff = function(dict) {
  return dict.ff;
};
var disj = function(dict) {
  return dict.disj;
};
var heytingAlgebraBoolean = {
  ff: false,
  tt: true,
  implies: function(a2) {
    return function(b10) {
      return disj(heytingAlgebraBoolean)(not(heytingAlgebraBoolean)(a2))(b10);
    };
  },
  conj: boolConj,
  disj: boolDisj,
  not: boolNot
};
var conj = function(dict) {
  return dict.conj;
};
var heytingAlgebraFunction = function(dictHeytingAlgebra) {
  var ff1 = ff(dictHeytingAlgebra);
  var tt1 = tt(dictHeytingAlgebra);
  var implies1 = implies(dictHeytingAlgebra);
  var conj1 = conj(dictHeytingAlgebra);
  var disj1 = disj(dictHeytingAlgebra);
  var not1 = not(dictHeytingAlgebra);
  return {
    ff: function(v) {
      return ff1;
    },
    tt: function(v) {
      return tt1;
    },
    implies: function(f) {
      return function(g) {
        return function(a2) {
          return implies1(f(a2))(g(a2));
        };
      };
    },
    conj: function(f) {
      return function(g) {
        return function(a2) {
          return conj1(f(a2))(g(a2));
        };
      };
    },
    disj: function(f) {
      return function(g) {
        return function(a2) {
          return disj1(f(a2))(g(a2));
        };
      };
    },
    not: function(f) {
      return function(a2) {
        return not1(f(a2));
      };
    }
  };
};

// output/Data.EuclideanRing/foreign.js
var intDegree = function(x4) {
  return Math.min(Math.abs(x4), 2147483647);
};
var intDiv = function(x4) {
  return function(y4) {
    if (y4 === 0) return 0;
    return y4 > 0 ? Math.floor(x4 / y4) : -Math.floor(x4 / -y4);
  };
};
var intMod = function(x4) {
  return function(y4) {
    if (y4 === 0) return 0;
    var yy = Math.abs(y4);
    return (x4 % yy + yy) % yy;
  };
};

// output/Data.CommutativeRing/index.js
var commutativeRingInt = {
  Ring0: function() {
    return ringInt;
  }
};

// output/Data.EuclideanRing/index.js
var mod = function(dict) {
  return dict.mod;
};
var euclideanRingInt = {
  degree: intDegree,
  div: intDiv,
  mod: intMod,
  CommutativeRing0: function() {
    return commutativeRingInt;
  }
};

// output/Data.Semigroup/foreign.js
var concatArray = function(xs) {
  return function(ys) {
    if (xs.length === 0) return ys;
    if (ys.length === 0) return xs;
    return xs.concat(ys);
  };
};

// output/Data.Semigroup/index.js
var semigroupArray = {
  append: concatArray
};
var append = function(dict) {
  return dict.append;
};

// output/Data.Monoid/index.js
var mempty = function(dict) {
  return dict.mempty;
};

// output/Data.Tuple/index.js
var Tuple = /* @__PURE__ */ (function() {
  function Tuple2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  Tuple2.create = function(value0) {
    return function(value1) {
      return new Tuple2(value0, value1);
    };
  };
  return Tuple2;
})();
var snd = function(v) {
  return v.value1;
};
var functorTuple = {
  map: function(f) {
    return function(m) {
      return new Tuple(m.value0, f(m.value1));
    };
  }
};
var fst = function(v) {
  return v.value0;
};

// output/Control.Monad.State.Class/index.js
var state = function(dict) {
  return dict.state;
};
var modify_ = function(dictMonadState) {
  var state1 = state(dictMonadState);
  return function(f) {
    return state1(function(s) {
      return new Tuple(unit, f(s));
    });
  };
};
var get = function(dictMonadState) {
  return state(dictMonadState)(function(s) {
    return new Tuple(s, s);
  });
};

// output/Data.Array/foreign.js
var rangeImpl = function(start3, end) {
  var step3 = start3 > end ? -1 : 1;
  var result = new Array(step3 * (end - start3) + 1);
  var i2 = start3, n = 0;
  while (i2 !== end) {
    result[n++] = i2;
    i2 += step3;
  }
  result[n] = i2;
  return result;
};
var replicateFill = function(count, value12) {
  if (count < 1) {
    return [];
  }
  var result = new Array(count);
  return result.fill(value12);
};
var replicatePolyfill = function(count, value12) {
  var result = [];
  var n = 0;
  for (var i2 = 0; i2 < count; i2++) {
    result[n++] = value12;
  }
  return result;
};
var replicateImpl = typeof Array.prototype.fill === "function" ? replicateFill : replicatePolyfill;
var fromFoldableImpl = /* @__PURE__ */ (function() {
  function Cons2(head3, tail2) {
    this.head = head3;
    this.tail = tail2;
  }
  var emptyList = {};
  function curryCons(head3) {
    return function(tail2) {
      return new Cons2(head3, tail2);
    };
  }
  function listToArray(list) {
    var result = [];
    var count = 0;
    var xs = list;
    while (xs !== emptyList) {
      result[count++] = xs.head;
      xs = xs.tail;
    }
    return result;
  }
  return function(foldr4, xs) {
    return listToArray(foldr4(curryCons)(emptyList)(xs));
  };
})();
var length = function(xs) {
  return xs.length;
};
var unconsImpl = function(empty8, next, xs) {
  return xs.length === 0 ? empty8({}) : next(xs[0])(xs.slice(1));
};
var indexImpl = function(just, nothing, xs, i2) {
  return i2 < 0 || i2 >= xs.length ? nothing : just(xs[i2]);
};
var findIndexImpl = function(just, nothing, f, xs) {
  for (var i2 = 0, l = xs.length; i2 < l; i2++) {
    if (f(xs[i2])) return just(i2);
  }
  return nothing;
};
var _deleteAt = function(just, nothing, i2, l) {
  if (i2 < 0 || i2 >= l.length) return nothing;
  var l1 = l.slice();
  l1.splice(i2, 1);
  return just(l1);
};
var reverse = function(l) {
  return l.slice().reverse();
};
var concat = function(xss) {
  if (xss.length <= 1e4) {
    return Array.prototype.concat.apply([], xss);
  }
  var result = [];
  for (var i2 = 0, l = xss.length; i2 < l; i2++) {
    var xs = xss[i2];
    for (var j = 0, m = xs.length; j < m; j++) {
      result.push(xs[j]);
    }
  }
  return result;
};
var sortByImpl = /* @__PURE__ */ (function() {
  function mergeFromTo(compare3, fromOrdering, xs1, xs2, from3, to) {
    var mid;
    var i2;
    var j;
    var k;
    var x4;
    var y4;
    var c;
    mid = from3 + (to - from3 >> 1);
    if (mid - from3 > 1) mergeFromTo(compare3, fromOrdering, xs2, xs1, from3, mid);
    if (to - mid > 1) mergeFromTo(compare3, fromOrdering, xs2, xs1, mid, to);
    i2 = from3;
    j = mid;
    k = from3;
    while (i2 < mid && j < to) {
      x4 = xs2[i2];
      y4 = xs2[j];
      c = fromOrdering(compare3(x4)(y4));
      if (c > 0) {
        xs1[k++] = y4;
        ++j;
      } else {
        xs1[k++] = x4;
        ++i2;
      }
    }
    while (i2 < mid) {
      xs1[k++] = xs2[i2++];
    }
    while (j < to) {
      xs1[k++] = xs2[j++];
    }
  }
  return function(compare3, fromOrdering, xs) {
    var out;
    if (xs.length < 2) return xs;
    out = xs.slice(0);
    mergeFromTo(compare3, fromOrdering, out, xs.slice(0), 0, xs.length);
    return out;
  };
})();
var sliceImpl = function(s, e, l) {
  return l.slice(s, e);
};
var zipWithImpl = function(f, xs, ys) {
  var l = xs.length < ys.length ? xs.length : ys.length;
  var result = new Array(l);
  for (var i2 = 0; i2 < l; i2++) {
    result[i2] = f(xs[i2])(ys[i2]);
  }
  return result;
};
var unsafeIndexImpl = function(xs, n) {
  return xs[n];
};

// output/Control.Monad/index.js
var unlessM = function(dictMonad) {
  var bind7 = bind(dictMonad.Bind1());
  var unless2 = unless(dictMonad.Applicative0());
  return function(mb) {
    return function(m) {
      return bind7(mb)(function(b10) {
        return unless2(b10)(m);
      });
    };
  };
};
var ap = function(dictMonad) {
  var bind7 = bind(dictMonad.Bind1());
  var pure11 = pure(dictMonad.Applicative0());
  return function(f) {
    return function(a2) {
      return bind7(f)(function(f$prime) {
        return bind7(a2)(function(a$prime) {
          return pure11(f$prime(a$prime));
        });
      });
    };
  };
};

// output/Data.Maybe/index.js
var identity4 = /* @__PURE__ */ identity(categoryFn);
var Nothing = /* @__PURE__ */ (function() {
  function Nothing2() {
  }
  ;
  Nothing2.value = new Nothing2();
  return Nothing2;
})();
var Just = /* @__PURE__ */ (function() {
  function Just2(value0) {
    this.value0 = value0;
  }
  ;
  Just2.create = function(value0) {
    return new Just2(value0);
  };
  return Just2;
})();
var maybe = function(v) {
  return function(v1) {
    return function(v2) {
      if (v2 instanceof Nothing) {
        return v;
      }
      ;
      if (v2 instanceof Just) {
        return v1(v2.value0);
      }
      ;
      throw new Error("Failed pattern match at Data.Maybe (line 237, column 1 - line 237, column 51): " + [v.constructor.name, v1.constructor.name, v2.constructor.name]);
    };
  };
};
var isNothing = /* @__PURE__ */ maybe(true)(/* @__PURE__ */ $$const(false));
var isJust = /* @__PURE__ */ maybe(false)(/* @__PURE__ */ $$const(true));
var functorMaybe = {
  map: function(v) {
    return function(v1) {
      if (v1 instanceof Just) {
        return new Just(v(v1.value0));
      }
      ;
      return Nothing.value;
    };
  }
};
var map2 = /* @__PURE__ */ map(functorMaybe);
var fromMaybe = function(a2) {
  return maybe(a2)(identity4);
};
var fromJust = function() {
  return function(v) {
    if (v instanceof Just) {
      return v.value0;
    }
    ;
    throw new Error("Failed pattern match at Data.Maybe (line 288, column 1 - line 288, column 46): " + [v.constructor.name]);
  };
};
var applyMaybe = {
  apply: function(v) {
    return function(v1) {
      if (v instanceof Just) {
        return map2(v.value0)(v1);
      }
      ;
      if (v instanceof Nothing) {
        return Nothing.value;
      }
      ;
      throw new Error("Failed pattern match at Data.Maybe (line 67, column 1 - line 69, column 30): " + [v.constructor.name, v1.constructor.name]);
    };
  },
  Functor0: function() {
    return functorMaybe;
  }
};
var bindMaybe = {
  bind: function(v) {
    return function(v1) {
      if (v instanceof Just) {
        return v1(v.value0);
      }
      ;
      if (v instanceof Nothing) {
        return Nothing.value;
      }
      ;
      throw new Error("Failed pattern match at Data.Maybe (line 125, column 1 - line 127, column 28): " + [v.constructor.name, v1.constructor.name]);
    };
  },
  Apply0: function() {
    return applyMaybe;
  }
};

// output/Data.Either/index.js
var Left = /* @__PURE__ */ (function() {
  function Left2(value0) {
    this.value0 = value0;
  }
  ;
  Left2.create = function(value0) {
    return new Left2(value0);
  };
  return Left2;
})();
var Right = /* @__PURE__ */ (function() {
  function Right2(value0) {
    this.value0 = value0;
  }
  ;
  Right2.create = function(value0) {
    return new Right2(value0);
  };
  return Right2;
})();
var either = function(v) {
  return function(v1) {
    return function(v2) {
      if (v2 instanceof Left) {
        return v(v2.value0);
      }
      ;
      if (v2 instanceof Right) {
        return v1(v2.value0);
      }
      ;
      throw new Error("Failed pattern match at Data.Either (line 208, column 1 - line 208, column 64): " + [v.constructor.name, v1.constructor.name, v2.constructor.name]);
    };
  };
};

// output/Effect/foreign.js
var pureE = function(a2) {
  return function() {
    return a2;
  };
};
var bindE = function(a2) {
  return function(f) {
    return function() {
      return f(a2())();
    };
  };
};

// output/Effect/index.js
var $runtime_lazy = function(name15, moduleName, init4) {
  var state3 = 0;
  var val;
  return function(lineNumber) {
    if (state3 === 2) return val;
    if (state3 === 1) throw new ReferenceError(name15 + " was needed before it finished initializing (module " + moduleName + ", line " + lineNumber + ")", moduleName, lineNumber);
    state3 = 1;
    val = init4();
    state3 = 2;
    return val;
  };
};
var monadEffect = {
  Applicative0: function() {
    return applicativeEffect;
  },
  Bind1: function() {
    return bindEffect;
  }
};
var bindEffect = {
  bind: bindE,
  Apply0: function() {
    return $lazy_applyEffect(0);
  }
};
var applicativeEffect = {
  pure: pureE,
  Apply0: function() {
    return $lazy_applyEffect(0);
  }
};
var $lazy_functorEffect = /* @__PURE__ */ $runtime_lazy("functorEffect", "Effect", function() {
  return {
    map: liftA1(applicativeEffect)
  };
});
var $lazy_applyEffect = /* @__PURE__ */ $runtime_lazy("applyEffect", "Effect", function() {
  return {
    apply: ap(monadEffect),
    Functor0: function() {
      return $lazy_functorEffect(0);
    }
  };
});
var functorEffect = /* @__PURE__ */ $lazy_functorEffect(20);

// output/Effect.Ref/foreign.js
var _new = function(val) {
  return function() {
    return { value: val };
  };
};
var read = function(ref2) {
  return function() {
    return ref2.value;
  };
};
var modifyImpl = function(f) {
  return function(ref2) {
    return function() {
      var t = f(ref2.value);
      ref2.value = t.state;
      return t.value;
    };
  };
};
var write = function(val) {
  return function(ref2) {
    return function() {
      ref2.value = val;
    };
  };
};

// output/Effect.Ref/index.js
var $$void2 = /* @__PURE__ */ $$void(functorEffect);
var $$new = _new;
var modify$prime = modifyImpl;
var modify = function(f) {
  return modify$prime(function(s) {
    var s$prime = f(s);
    return {
      state: s$prime,
      value: s$prime
    };
  });
};
var modify_2 = function(f) {
  return function(s) {
    return $$void2(modify(f)(s));
  };
};

// output/Control.Monad.Rec.Class/index.js
var bindFlipped2 = /* @__PURE__ */ bindFlipped(bindEffect);
var map3 = /* @__PURE__ */ map(functorEffect);
var Loop = /* @__PURE__ */ (function() {
  function Loop2(value0) {
    this.value0 = value0;
  }
  ;
  Loop2.create = function(value0) {
    return new Loop2(value0);
  };
  return Loop2;
})();
var Done = /* @__PURE__ */ (function() {
  function Done2(value0) {
    this.value0 = value0;
  }
  ;
  Done2.create = function(value0) {
    return new Done2(value0);
  };
  return Done2;
})();
var tailRecM = function(dict) {
  return dict.tailRecM;
};
var monadRecEffect = {
  tailRecM: function(f) {
    return function(a2) {
      var fromDone = function(v) {
        if (v instanceof Done) {
          return v.value0;
        }
        ;
        throw new Error("Failed pattern match at Control.Monad.Rec.Class (line 137, column 30 - line 137, column 44): " + [v.constructor.name]);
      };
      return function __do2() {
        var r = bindFlipped2($$new)(f(a2))();
        (function() {
          while (!(function __do3() {
            var v = read(r)();
            if (v instanceof Loop) {
              var e = f(v.value0)();
              write(e)(r)();
              return false;
            }
            ;
            if (v instanceof Done) {
              return true;
            }
            ;
            throw new Error("Failed pattern match at Control.Monad.Rec.Class (line 128, column 22 - line 133, column 28): " + [v.constructor.name]);
          })()) {
          }
          ;
          return {};
        })();
        return map3(fromDone)(read(r))();
      };
    };
  },
  Monad0: function() {
    return monadEffect;
  }
};

// output/Data.Array.ST/foreign.js
function unsafeFreezeThawImpl(xs) {
  return xs;
}
var unsafeFreezeImpl = unsafeFreezeThawImpl;
function copyImpl(xs) {
  return xs.slice();
}
var thawImpl = copyImpl;
var pushImpl = function(a2, xs) {
  return xs.push(a2);
};

// output/Control.Monad.ST.Uncurried/foreign.js
var runSTFn1 = function runSTFn12(fn) {
  return function(a2) {
    return function() {
      return fn(a2);
    };
  };
};
var runSTFn2 = function runSTFn22(fn) {
  return function(a2) {
    return function(b10) {
      return function() {
        return fn(a2, b10);
      };
    };
  };
};

// output/Data.Array.ST/index.js
var unsafeFreeze = /* @__PURE__ */ runSTFn1(unsafeFreezeImpl);
var thaw = /* @__PURE__ */ runSTFn1(thawImpl);
var withArray = function(f) {
  return function(xs) {
    return function __do2() {
      var result = thaw(xs)();
      f(result)();
      return unsafeFreeze(result)();
    };
  };
};
var push = /* @__PURE__ */ runSTFn2(pushImpl);

// output/Data.Foldable/foreign.js
var foldrArray = function(f) {
  return function(init4) {
    return function(xs) {
      var acc = init4;
      var len = xs.length;
      for (var i2 = len - 1; i2 >= 0; i2--) {
        acc = f(xs[i2])(acc);
      }
      return acc;
    };
  };
};
var foldlArray = function(f) {
  return function(init4) {
    return function(xs) {
      var acc = init4;
      var len = xs.length;
      for (var i2 = 0; i2 < len; i2++) {
        acc = f(acc)(xs[i2]);
      }
      return acc;
    };
  };
};

// output/Control.Plus/index.js
var empty = function(dict) {
  return dict.empty;
};

// output/Data.Bifunctor/index.js
var bimap = function(dict) {
  return dict.bimap;
};

// output/Unsafe.Coerce/foreign.js
var unsafeCoerce2 = function(x4) {
  return x4;
};

// output/Safe.Coerce/index.js
var coerce = function() {
  return unsafeCoerce2;
};

// output/Data.Newtype/index.js
var coerce2 = /* @__PURE__ */ coerce();
var unwrap = function() {
  return coerce2;
};

// output/Data.Foldable/index.js
var foldr = function(dict) {
  return dict.foldr;
};
var traverse_ = function(dictApplicative) {
  var applySecond2 = applySecond(dictApplicative.Apply0());
  var pure11 = pure(dictApplicative);
  return function(dictFoldable) {
    var foldr22 = foldr(dictFoldable);
    return function(f) {
      return foldr22(function($454) {
        return applySecond2(f($454));
      })(pure11(unit));
    };
  };
};
var for_ = function(dictApplicative) {
  var traverse_14 = traverse_(dictApplicative);
  return function(dictFoldable) {
    return flip(traverse_14(dictFoldable));
  };
};
var foldl = function(dict) {
  return dict.foldl;
};
var foldableMaybe = {
  foldr: function(v) {
    return function(v1) {
      return function(v2) {
        if (v2 instanceof Nothing) {
          return v1;
        }
        ;
        if (v2 instanceof Just) {
          return v(v2.value0)(v1);
        }
        ;
        throw new Error("Failed pattern match at Data.Foldable (line 138, column 1 - line 144, column 27): " + [v.constructor.name, v1.constructor.name, v2.constructor.name]);
      };
    };
  },
  foldl: function(v) {
    return function(v1) {
      return function(v2) {
        if (v2 instanceof Nothing) {
          return v1;
        }
        ;
        if (v2 instanceof Just) {
          return v(v1)(v2.value0);
        }
        ;
        throw new Error("Failed pattern match at Data.Foldable (line 138, column 1 - line 144, column 27): " + [v.constructor.name, v1.constructor.name, v2.constructor.name]);
      };
    };
  },
  foldMap: function(dictMonoid) {
    var mempty2 = mempty(dictMonoid);
    return function(v) {
      return function(v1) {
        if (v1 instanceof Nothing) {
          return mempty2;
        }
        ;
        if (v1 instanceof Just) {
          return v(v1.value0);
        }
        ;
        throw new Error("Failed pattern match at Data.Foldable (line 138, column 1 - line 144, column 27): " + [v.constructor.name, v1.constructor.name]);
      };
    };
  }
};
var foldMapDefaultR = function(dictFoldable) {
  var foldr22 = foldr(dictFoldable);
  return function(dictMonoid) {
    var append9 = append(dictMonoid.Semigroup0());
    var mempty2 = mempty(dictMonoid);
    return function(f) {
      return foldr22(function(x4) {
        return function(acc) {
          return append9(f(x4))(acc);
        };
      })(mempty2);
    };
  };
};
var foldableArray = {
  foldr: foldrArray,
  foldl: foldlArray,
  foldMap: function(dictMonoid) {
    return foldMapDefaultR(foldableArray)(dictMonoid);
  }
};

// output/Data.Function.Uncurried/foreign.js
var runFn2 = function(fn) {
  return function(a2) {
    return function(b10) {
      return fn(a2, b10);
    };
  };
};
var runFn3 = function(fn) {
  return function(a2) {
    return function(b10) {
      return function(c) {
        return fn(a2, b10, c);
      };
    };
  };
};
var runFn4 = function(fn) {
  return function(a2) {
    return function(b10) {
      return function(c) {
        return function(d) {
          return fn(a2, b10, c, d);
        };
      };
    };
  };
};

// output/Data.FunctorWithIndex/foreign.js
var mapWithIndexArray = function(f) {
  return function(xs) {
    var l = xs.length;
    var result = Array(l);
    for (var i2 = 0; i2 < l; i2++) {
      result[i2] = f(i2)(xs[i2]);
    }
    return result;
  };
};

// output/Data.FunctorWithIndex/index.js
var mapWithIndex = function(dict) {
  return dict.mapWithIndex;
};
var functorWithIndexArray = {
  mapWithIndex: mapWithIndexArray,
  Functor0: function() {
    return functorArray;
  }
};

// output/Data.Traversable/foreign.js
var traverseArrayImpl = /* @__PURE__ */ (function() {
  function array1(a2) {
    return [a2];
  }
  function array2(a2) {
    return function(b10) {
      return [a2, b10];
    };
  }
  function array3(a2) {
    return function(b10) {
      return function(c) {
        return [a2, b10, c];
      };
    };
  }
  function concat22(xs) {
    return function(ys) {
      return xs.concat(ys);
    };
  }
  return function(apply2) {
    return function(map23) {
      return function(pure11) {
        return function(f) {
          return function(array4) {
            function go2(bot, top2) {
              switch (top2 - bot) {
                case 0:
                  return pure11([]);
                case 1:
                  return map23(array1)(f(array4[bot]));
                case 2:
                  return apply2(map23(array2)(f(array4[bot])))(f(array4[bot + 1]));
                case 3:
                  return apply2(apply2(map23(array3)(f(array4[bot])))(f(array4[bot + 1])))(f(array4[bot + 2]));
                default:
                  var pivot = bot + Math.floor((top2 - bot) / 4) * 2;
                  return apply2(map23(concat22)(go2(bot, pivot)))(go2(pivot, top2));
              }
            }
            return go2(0, array4.length);
          };
        };
      };
    };
  };
})();

// output/Data.Traversable/index.js
var identity5 = /* @__PURE__ */ identity(categoryFn);
var traverse = function(dict) {
  return dict.traverse;
};
var sequenceDefault = function(dictTraversable) {
  var traverse22 = traverse(dictTraversable);
  return function(dictApplicative) {
    return traverse22(dictApplicative)(identity5);
  };
};
var traversableArray = {
  traverse: function(dictApplicative) {
    var Apply0 = dictApplicative.Apply0();
    return traverseArrayImpl(apply(Apply0))(map(Apply0.Functor0()))(pure(dictApplicative));
  },
  sequence: function(dictApplicative) {
    return sequenceDefault(traversableArray)(dictApplicative);
  },
  Functor0: function() {
    return functorArray;
  },
  Foldable1: function() {
    return foldableArray;
  }
};
var sequence = function(dict) {
  return dict.sequence;
};

// output/Data.Array/index.js
var map4 = /* @__PURE__ */ map(functorMaybe);
var fromJust2 = /* @__PURE__ */ fromJust();
var append2 = /* @__PURE__ */ append(semigroupArray);
var zipWith = /* @__PURE__ */ runFn3(zipWithImpl);
var unsafeIndex = function() {
  return runFn2(unsafeIndexImpl);
};
var unsafeIndex1 = /* @__PURE__ */ unsafeIndex();
var uncons = /* @__PURE__ */ (function() {
  return runFn3(unconsImpl)($$const(Nothing.value))(function(x4) {
    return function(xs) {
      return new Just({
        head: x4,
        tail: xs
      });
    };
  });
})();
var sortBy = function(comp) {
  return runFn3(sortByImpl)(comp)(function(v) {
    if (v instanceof GT) {
      return 1;
    }
    ;
    if (v instanceof EQ) {
      return 0;
    }
    ;
    if (v instanceof LT) {
      return -1 | 0;
    }
    ;
    throw new Error("Failed pattern match at Data.Array (line 897, column 38 - line 900, column 11): " + [v.constructor.name]);
  });
};
var snoc = function(xs) {
  return function(x4) {
    return withArray(push(x4))(xs)();
  };
};
var slice = /* @__PURE__ */ runFn3(sliceImpl);
var singleton2 = function(a2) {
  return [a2];
};
var range2 = /* @__PURE__ */ runFn2(rangeImpl);
var $$null = function(xs) {
  return length(xs) === 0;
};
var index = /* @__PURE__ */ (function() {
  return runFn4(indexImpl)(Just.create)(Nothing.value);
})();
var last = function(xs) {
  return index(xs)(length(xs) - 1 | 0);
};
var head = function(xs) {
  return index(xs)(0);
};
var fromFoldable = function(dictFoldable) {
  return runFn2(fromFoldableImpl)(foldr(dictFoldable));
};
var foldl2 = /* @__PURE__ */ foldl(foldableArray);
var findIndex = /* @__PURE__ */ (function() {
  return runFn4(findIndexImpl)(Just.create)(Nothing.value);
})();
var find2 = function(f) {
  return function(xs) {
    return map4(unsafeIndex1(xs))(findIndex(f)(xs));
  };
};
var drop = function(n) {
  return function(xs) {
    var $173 = n < 1;
    if ($173) {
      return xs;
    }
    ;
    return slice(n)(length(xs))(xs);
  };
};
var takeEnd = function(n) {
  return function(xs) {
    return drop(length(xs) - n | 0)(xs);
  };
};
var deleteAt = /* @__PURE__ */ (function() {
  return runFn4(_deleteAt)(Just.create)(Nothing.value);
})();
var deleteBy = function(v) {
  return function(v1) {
    return function(v2) {
      if (v2.length === 0) {
        return [];
      }
      ;
      return maybe(v2)(function(i2) {
        return fromJust2(deleteAt(i2)(v2));
      })(findIndex(v(v1))(v2));
    };
  };
};
var cons = function(x4) {
  return function(xs) {
    return append2([x4])(xs);
  };
};
var concatMap = /* @__PURE__ */ flip(/* @__PURE__ */ bind(bindArray));
var mapMaybe = function(f) {
  return concatMap((function() {
    var $189 = maybe([])(singleton2);
    return function($190) {
      return $189(f($190));
    };
  })());
};

// output/Data.Int/foreign.js
var toNumber = function(n) {
  return n;
};

// output/Data.Nullable/foreign.js
var nullImpl = null;
function nullable(a2, r, f) {
  return a2 == null ? r : f(a2);
}
function notNull(x4) {
  return x4;
}

// output/Data.Nullable/index.js
var toNullable = /* @__PURE__ */ maybe(nullImpl)(notNull);
var toMaybe = function(n) {
  return nullable(n, Nothing.value, Just.create);
};

// output/Effect.Aff/foreign.js
var Aff = (function() {
  var EMPTY = {};
  var PURE = "Pure";
  var THROW = "Throw";
  var CATCH = "Catch";
  var SYNC = "Sync";
  var ASYNC = "Async";
  var BIND = "Bind";
  var BRACKET = "Bracket";
  var FORK = "Fork";
  var SEQ = "Sequential";
  var MAP = "Map";
  var APPLY = "Apply";
  var ALT = "Alt";
  var CONS = "Cons";
  var RESUME = "Resume";
  var RELEASE = "Release";
  var FINALIZER = "Finalizer";
  var FINALIZED = "Finalized";
  var FORKED = "Forked";
  var FIBER = "Fiber";
  var THUNK = "Thunk";
  function Aff2(tag, _1, _2, _3) {
    this.tag = tag;
    this._1 = _1;
    this._2 = _2;
    this._3 = _3;
  }
  function AffCtr(tag) {
    var fn = function(_1, _2, _3) {
      return new Aff2(tag, _1, _2, _3);
    };
    fn.tag = tag;
    return fn;
  }
  function nonCanceler2(error4) {
    return new Aff2(PURE, void 0);
  }
  function runEff(eff) {
    try {
      eff();
    } catch (error4) {
      setTimeout(function() {
        throw error4;
      }, 0);
    }
  }
  function runSync(left, right, eff) {
    try {
      return right(eff());
    } catch (error4) {
      return left(error4);
    }
  }
  function runAsync(left, eff, k) {
    try {
      return eff(k)();
    } catch (error4) {
      k(left(error4))();
      return nonCanceler2;
    }
  }
  var Scheduler = (function() {
    var limit = 1024;
    var size4 = 0;
    var ix = 0;
    var queue = new Array(limit);
    var draining = false;
    function drain() {
      var thunk;
      draining = true;
      while (size4 !== 0) {
        size4--;
        thunk = queue[ix];
        queue[ix] = void 0;
        ix = (ix + 1) % limit;
        thunk();
      }
      draining = false;
    }
    return {
      isDraining: function() {
        return draining;
      },
      enqueue: function(cb) {
        var i2, tmp;
        if (size4 === limit) {
          tmp = draining;
          drain();
          draining = tmp;
        }
        queue[(ix + size4) % limit] = cb;
        size4++;
        if (!draining) {
          drain();
        }
      }
    };
  })();
  function Supervisor(util) {
    var fibers = {};
    var fiberId = 0;
    var count = 0;
    return {
      register: function(fiber) {
        var fid = fiberId++;
        fiber.onComplete({
          rethrow: true,
          handler: function(result) {
            return function() {
              count--;
              delete fibers[fid];
            };
          }
        })();
        fibers[fid] = fiber;
        count++;
      },
      isEmpty: function() {
        return count === 0;
      },
      killAll: function(killError, cb) {
        return function() {
          if (count === 0) {
            return cb();
          }
          var killCount = 0;
          var kills = {};
          function kill2(fid) {
            kills[fid] = fibers[fid].kill(killError, function(result) {
              return function() {
                delete kills[fid];
                killCount--;
                if (util.isLeft(result) && util.fromLeft(result)) {
                  setTimeout(function() {
                    throw util.fromLeft(result);
                  }, 0);
                }
                if (killCount === 0) {
                  cb();
                }
              };
            })();
          }
          for (var k in fibers) {
            if (fibers.hasOwnProperty(k)) {
              killCount++;
              kill2(k);
            }
          }
          fibers = {};
          fiberId = 0;
          count = 0;
          return function(error4) {
            return new Aff2(SYNC, function() {
              for (var k2 in kills) {
                if (kills.hasOwnProperty(k2)) {
                  kills[k2]();
                }
              }
            });
          };
        };
      }
    };
  }
  var SUSPENDED = 0;
  var CONTINUE = 1;
  var STEP_BIND = 2;
  var STEP_RESULT = 3;
  var PENDING = 4;
  var RETURN = 5;
  var COMPLETED = 6;
  function Fiber(util, supervisor, aff) {
    var runTick = 0;
    var status = SUSPENDED;
    var step3 = aff;
    var fail2 = null;
    var interrupt = null;
    var bhead = null;
    var btail = null;
    var attempts = null;
    var bracketCount = 0;
    var joinId = 0;
    var joins = null;
    var rethrow = true;
    function run3(localRunTick) {
      var tmp, result, attempt;
      while (true) {
        tmp = null;
        result = null;
        attempt = null;
        switch (status) {
          case STEP_BIND:
            status = CONTINUE;
            try {
              step3 = bhead(step3);
              if (btail === null) {
                bhead = null;
              } else {
                bhead = btail._1;
                btail = btail._2;
              }
            } catch (e) {
              status = RETURN;
              fail2 = util.left(e);
              step3 = null;
            }
            break;
          case STEP_RESULT:
            if (util.isLeft(step3)) {
              status = RETURN;
              fail2 = step3;
              step3 = null;
            } else if (bhead === null) {
              status = RETURN;
            } else {
              status = STEP_BIND;
              step3 = util.fromRight(step3);
            }
            break;
          case CONTINUE:
            switch (step3.tag) {
              case BIND:
                if (bhead) {
                  btail = new Aff2(CONS, bhead, btail);
                }
                bhead = step3._2;
                status = CONTINUE;
                step3 = step3._1;
                break;
              case PURE:
                if (bhead === null) {
                  status = RETURN;
                  step3 = util.right(step3._1);
                } else {
                  status = STEP_BIND;
                  step3 = step3._1;
                }
                break;
              case SYNC:
                status = STEP_RESULT;
                step3 = runSync(util.left, util.right, step3._1);
                break;
              case ASYNC:
                status = PENDING;
                step3 = runAsync(util.left, step3._1, function(result2) {
                  return function() {
                    if (runTick !== localRunTick) {
                      return;
                    }
                    runTick++;
                    Scheduler.enqueue(function() {
                      if (runTick !== localRunTick + 1) {
                        return;
                      }
                      status = STEP_RESULT;
                      step3 = result2;
                      run3(runTick);
                    });
                  };
                });
                return;
              case THROW:
                status = RETURN;
                fail2 = util.left(step3._1);
                step3 = null;
                break;
              // Enqueue the Catch so that we can call the error handler later on
              // in case of an exception.
              case CATCH:
                if (bhead === null) {
                  attempts = new Aff2(CONS, step3, attempts, interrupt);
                } else {
                  attempts = new Aff2(CONS, step3, new Aff2(CONS, new Aff2(RESUME, bhead, btail), attempts, interrupt), interrupt);
                }
                bhead = null;
                btail = null;
                status = CONTINUE;
                step3 = step3._1;
                break;
              // Enqueue the Bracket so that we can call the appropriate handlers
              // after resource acquisition.
              case BRACKET:
                bracketCount++;
                if (bhead === null) {
                  attempts = new Aff2(CONS, step3, attempts, interrupt);
                } else {
                  attempts = new Aff2(CONS, step3, new Aff2(CONS, new Aff2(RESUME, bhead, btail), attempts, interrupt), interrupt);
                }
                bhead = null;
                btail = null;
                status = CONTINUE;
                step3 = step3._1;
                break;
              case FORK:
                status = STEP_RESULT;
                tmp = Fiber(util, supervisor, step3._2);
                if (supervisor) {
                  supervisor.register(tmp);
                }
                if (step3._1) {
                  tmp.run();
                }
                step3 = util.right(tmp);
                break;
              case SEQ:
                status = CONTINUE;
                step3 = sequential3(util, supervisor, step3._1);
                break;
            }
            break;
          case RETURN:
            bhead = null;
            btail = null;
            if (attempts === null) {
              status = COMPLETED;
              step3 = interrupt || fail2 || step3;
            } else {
              tmp = attempts._3;
              attempt = attempts._1;
              attempts = attempts._2;
              switch (attempt.tag) {
                // We cannot recover from an unmasked interrupt. Otherwise we should
                // continue stepping, or run the exception handler if an exception
                // was raised.
                case CATCH:
                  if (interrupt && interrupt !== tmp && bracketCount === 0) {
                    status = RETURN;
                  } else if (fail2) {
                    status = CONTINUE;
                    step3 = attempt._2(util.fromLeft(fail2));
                    fail2 = null;
                  }
                  break;
                // We cannot resume from an unmasked interrupt or exception.
                case RESUME:
                  if (interrupt && interrupt !== tmp && bracketCount === 0 || fail2) {
                    status = RETURN;
                  } else {
                    bhead = attempt._1;
                    btail = attempt._2;
                    status = STEP_BIND;
                    step3 = util.fromRight(step3);
                  }
                  break;
                // If we have a bracket, we should enqueue the handlers,
                // and continue with the success branch only if the fiber has
                // not been interrupted. If the bracket acquisition failed, we
                // should not run either.
                case BRACKET:
                  bracketCount--;
                  if (fail2 === null) {
                    result = util.fromRight(step3);
                    attempts = new Aff2(CONS, new Aff2(RELEASE, attempt._2, result), attempts, tmp);
                    if (interrupt === tmp || bracketCount > 0) {
                      status = CONTINUE;
                      step3 = attempt._3(result);
                    }
                  }
                  break;
                // Enqueue the appropriate handler. We increase the bracket count
                // because it should not be cancelled.
                case RELEASE:
                  attempts = new Aff2(CONS, new Aff2(FINALIZED, step3, fail2), attempts, interrupt);
                  status = CONTINUE;
                  if (interrupt && interrupt !== tmp && bracketCount === 0) {
                    step3 = attempt._1.killed(util.fromLeft(interrupt))(attempt._2);
                  } else if (fail2) {
                    step3 = attempt._1.failed(util.fromLeft(fail2))(attempt._2);
                  } else {
                    step3 = attempt._1.completed(util.fromRight(step3))(attempt._2);
                  }
                  fail2 = null;
                  bracketCount++;
                  break;
                case FINALIZER:
                  bracketCount++;
                  attempts = new Aff2(CONS, new Aff2(FINALIZED, step3, fail2), attempts, interrupt);
                  status = CONTINUE;
                  step3 = attempt._1;
                  break;
                case FINALIZED:
                  bracketCount--;
                  status = RETURN;
                  step3 = attempt._1;
                  fail2 = attempt._2;
                  break;
              }
            }
            break;
          case COMPLETED:
            for (var k in joins) {
              if (joins.hasOwnProperty(k)) {
                rethrow = rethrow && joins[k].rethrow;
                runEff(joins[k].handler(step3));
              }
            }
            joins = null;
            if (interrupt && fail2) {
              setTimeout(function() {
                throw util.fromLeft(fail2);
              }, 0);
            } else if (util.isLeft(step3) && rethrow) {
              setTimeout(function() {
                if (rethrow) {
                  throw util.fromLeft(step3);
                }
              }, 0);
            }
            return;
          case SUSPENDED:
            status = CONTINUE;
            break;
          case PENDING:
            return;
        }
      }
    }
    function onComplete(join5) {
      return function() {
        if (status === COMPLETED) {
          rethrow = rethrow && join5.rethrow;
          join5.handler(step3)();
          return function() {
          };
        }
        var jid = joinId++;
        joins = joins || {};
        joins[jid] = join5;
        return function() {
          if (joins !== null) {
            delete joins[jid];
          }
        };
      };
    }
    function kill2(error4, cb) {
      return function() {
        if (status === COMPLETED) {
          cb(util.right(void 0))();
          return function() {
          };
        }
        var canceler = onComplete({
          rethrow: false,
          handler: function() {
            return cb(util.right(void 0));
          }
        })();
        switch (status) {
          case SUSPENDED:
            interrupt = util.left(error4);
            status = COMPLETED;
            step3 = interrupt;
            run3(runTick);
            break;
          case PENDING:
            if (interrupt === null) {
              interrupt = util.left(error4);
            }
            if (bracketCount === 0) {
              if (status === PENDING) {
                attempts = new Aff2(CONS, new Aff2(FINALIZER, step3(error4)), attempts, interrupt);
              }
              status = RETURN;
              step3 = null;
              fail2 = null;
              run3(++runTick);
            }
            break;
          default:
            if (interrupt === null) {
              interrupt = util.left(error4);
            }
            if (bracketCount === 0) {
              status = RETURN;
              step3 = null;
              fail2 = null;
            }
        }
        return canceler;
      };
    }
    function join4(cb) {
      return function() {
        var canceler = onComplete({
          rethrow: false,
          handler: cb
        })();
        if (status === SUSPENDED) {
          run3(runTick);
        }
        return canceler;
      };
    }
    return {
      kill: kill2,
      join: join4,
      onComplete,
      isSuspended: function() {
        return status === SUSPENDED;
      },
      run: function() {
        if (status === SUSPENDED) {
          if (!Scheduler.isDraining()) {
            Scheduler.enqueue(function() {
              run3(runTick);
            });
          } else {
            run3(runTick);
          }
        }
      }
    };
  }
  function runPar(util, supervisor, par, cb) {
    var fiberId = 0;
    var fibers = {};
    var killId = 0;
    var kills = {};
    var early = new Error("[ParAff] Early exit");
    var interrupt = null;
    var root2 = EMPTY;
    function kill2(error4, par2, cb2) {
      var step3 = par2;
      var head3 = null;
      var tail2 = null;
      var count = 0;
      var kills2 = {};
      var tmp, kid;
      loop: while (true) {
        tmp = null;
        switch (step3.tag) {
          case FORKED:
            if (step3._3 === EMPTY) {
              tmp = fibers[step3._1];
              kills2[count++] = tmp.kill(error4, function(result) {
                return function() {
                  count--;
                  if (count === 0) {
                    cb2(result)();
                  }
                };
              });
            }
            if (head3 === null) {
              break loop;
            }
            step3 = head3._2;
            if (tail2 === null) {
              head3 = null;
            } else {
              head3 = tail2._1;
              tail2 = tail2._2;
            }
            break;
          case MAP:
            step3 = step3._2;
            break;
          case APPLY:
          case ALT:
            if (head3) {
              tail2 = new Aff2(CONS, head3, tail2);
            }
            head3 = step3;
            step3 = step3._1;
            break;
        }
      }
      if (count === 0) {
        cb2(util.right(void 0))();
      } else {
        kid = 0;
        tmp = count;
        for (; kid < tmp; kid++) {
          kills2[kid] = kills2[kid]();
        }
      }
      return kills2;
    }
    function join4(result, head3, tail2) {
      var fail2, step3, lhs, rhs, tmp, kid;
      if (util.isLeft(result)) {
        fail2 = result;
        step3 = null;
      } else {
        step3 = result;
        fail2 = null;
      }
      loop: while (true) {
        lhs = null;
        rhs = null;
        tmp = null;
        kid = null;
        if (interrupt !== null) {
          return;
        }
        if (head3 === null) {
          cb(fail2 || step3)();
          return;
        }
        if (head3._3 !== EMPTY) {
          return;
        }
        switch (head3.tag) {
          case MAP:
            if (fail2 === null) {
              head3._3 = util.right(head3._1(util.fromRight(step3)));
              step3 = head3._3;
            } else {
              head3._3 = fail2;
            }
            break;
          case APPLY:
            lhs = head3._1._3;
            rhs = head3._2._3;
            if (fail2) {
              head3._3 = fail2;
              tmp = true;
              kid = killId++;
              kills[kid] = kill2(early, fail2 === lhs ? head3._2 : head3._1, function() {
                return function() {
                  delete kills[kid];
                  if (tmp) {
                    tmp = false;
                  } else if (tail2 === null) {
                    join4(fail2, null, null);
                  } else {
                    join4(fail2, tail2._1, tail2._2);
                  }
                };
              });
              if (tmp) {
                tmp = false;
                return;
              }
            } else if (lhs === EMPTY || rhs === EMPTY) {
              return;
            } else {
              step3 = util.right(util.fromRight(lhs)(util.fromRight(rhs)));
              head3._3 = step3;
            }
            break;
          case ALT:
            lhs = head3._1._3;
            rhs = head3._2._3;
            if (lhs === EMPTY && util.isLeft(rhs) || rhs === EMPTY && util.isLeft(lhs)) {
              return;
            }
            if (lhs !== EMPTY && util.isLeft(lhs) && rhs !== EMPTY && util.isLeft(rhs)) {
              fail2 = step3 === lhs ? rhs : lhs;
              step3 = null;
              head3._3 = fail2;
            } else {
              head3._3 = step3;
              tmp = true;
              kid = killId++;
              kills[kid] = kill2(early, step3 === lhs ? head3._2 : head3._1, function() {
                return function() {
                  delete kills[kid];
                  if (tmp) {
                    tmp = false;
                  } else if (tail2 === null) {
                    join4(step3, null, null);
                  } else {
                    join4(step3, tail2._1, tail2._2);
                  }
                };
              });
              if (tmp) {
                tmp = false;
                return;
              }
            }
            break;
        }
        if (tail2 === null) {
          head3 = null;
        } else {
          head3 = tail2._1;
          tail2 = tail2._2;
        }
      }
    }
    function resolve(fiber) {
      return function(result) {
        return function() {
          delete fibers[fiber._1];
          fiber._3 = result;
          join4(result, fiber._2._1, fiber._2._2);
        };
      };
    }
    function run3() {
      var status = CONTINUE;
      var step3 = par;
      var head3 = null;
      var tail2 = null;
      var tmp, fid;
      loop: while (true) {
        tmp = null;
        fid = null;
        switch (status) {
          case CONTINUE:
            switch (step3.tag) {
              case MAP:
                if (head3) {
                  tail2 = new Aff2(CONS, head3, tail2);
                }
                head3 = new Aff2(MAP, step3._1, EMPTY, EMPTY);
                step3 = step3._2;
                break;
              case APPLY:
                if (head3) {
                  tail2 = new Aff2(CONS, head3, tail2);
                }
                head3 = new Aff2(APPLY, EMPTY, step3._2, EMPTY);
                step3 = step3._1;
                break;
              case ALT:
                if (head3) {
                  tail2 = new Aff2(CONS, head3, tail2);
                }
                head3 = new Aff2(ALT, EMPTY, step3._2, EMPTY);
                step3 = step3._1;
                break;
              default:
                fid = fiberId++;
                status = RETURN;
                tmp = step3;
                step3 = new Aff2(FORKED, fid, new Aff2(CONS, head3, tail2), EMPTY);
                tmp = Fiber(util, supervisor, tmp);
                tmp.onComplete({
                  rethrow: false,
                  handler: resolve(step3)
                })();
                fibers[fid] = tmp;
                if (supervisor) {
                  supervisor.register(tmp);
                }
            }
            break;
          case RETURN:
            if (head3 === null) {
              break loop;
            }
            if (head3._1 === EMPTY) {
              head3._1 = step3;
              status = CONTINUE;
              step3 = head3._2;
              head3._2 = EMPTY;
            } else {
              head3._2 = step3;
              step3 = head3;
              if (tail2 === null) {
                head3 = null;
              } else {
                head3 = tail2._1;
                tail2 = tail2._2;
              }
            }
        }
      }
      root2 = step3;
      for (fid = 0; fid < fiberId; fid++) {
        fibers[fid].run();
      }
    }
    function cancel(error4, cb2) {
      interrupt = util.left(error4);
      var innerKills;
      for (var kid in kills) {
        if (kills.hasOwnProperty(kid)) {
          innerKills = kills[kid];
          for (kid in innerKills) {
            if (innerKills.hasOwnProperty(kid)) {
              innerKills[kid]();
            }
          }
        }
      }
      kills = null;
      var newKills = kill2(error4, root2, cb2);
      return function(killError) {
        return new Aff2(ASYNC, function(killCb) {
          return function() {
            for (var kid2 in newKills) {
              if (newKills.hasOwnProperty(kid2)) {
                newKills[kid2]();
              }
            }
            return nonCanceler2;
          };
        });
      };
    }
    run3();
    return function(killError) {
      return new Aff2(ASYNC, function(killCb) {
        return function() {
          return cancel(killError, killCb);
        };
      });
    };
  }
  function sequential3(util, supervisor, par) {
    return new Aff2(ASYNC, function(cb) {
      return function() {
        return runPar(util, supervisor, par, cb);
      };
    });
  }
  Aff2.EMPTY = EMPTY;
  Aff2.Pure = AffCtr(PURE);
  Aff2.Throw = AffCtr(THROW);
  Aff2.Catch = AffCtr(CATCH);
  Aff2.Sync = AffCtr(SYNC);
  Aff2.Async = AffCtr(ASYNC);
  Aff2.Bind = AffCtr(BIND);
  Aff2.Bracket = AffCtr(BRACKET);
  Aff2.Fork = AffCtr(FORK);
  Aff2.Seq = AffCtr(SEQ);
  Aff2.ParMap = AffCtr(MAP);
  Aff2.ParApply = AffCtr(APPLY);
  Aff2.ParAlt = AffCtr(ALT);
  Aff2.Fiber = Fiber;
  Aff2.Supervisor = Supervisor;
  Aff2.Scheduler = Scheduler;
  Aff2.nonCanceler = nonCanceler2;
  return Aff2;
})();
var _pure = Aff.Pure;
var _throwError = Aff.Throw;
function _catchError(aff) {
  return function(k) {
    return Aff.Catch(aff, k);
  };
}
function _map(f) {
  return function(aff) {
    if (aff.tag === Aff.Pure.tag) {
      return Aff.Pure(f(aff._1));
    } else {
      return Aff.Bind(aff, function(value12) {
        return Aff.Pure(f(value12));
      });
    }
  };
}
function _bind(aff) {
  return function(k) {
    return Aff.Bind(aff, k);
  };
}
function _fork(immediate) {
  return function(aff) {
    return Aff.Fork(immediate, aff);
  };
}
var _liftEffect = Aff.Sync;
function _parAffMap(f) {
  return function(aff) {
    return Aff.ParMap(f, aff);
  };
}
function _parAffApply(aff1) {
  return function(aff2) {
    return Aff.ParApply(aff1, aff2);
  };
}
var makeAff = Aff.Async;
function generalBracket(acquire) {
  return function(options2) {
    return function(k) {
      return Aff.Bracket(acquire, options2, k);
    };
  };
}
function _makeFiber(util, aff) {
  return function() {
    return Aff.Fiber(util, null, aff);
  };
}
var _sequential = Aff.Seq;

// output/Effect.Exception/foreign.js
function error(msg) {
  return new Error(msg);
}
function throwException(e) {
  return function() {
    throw e;
  };
}

// output/Effect.Exception/index.js
var $$throw = function($4) {
  return throwException(error($4));
};

// output/Control.Monad.Error.Class/index.js
var throwError = function(dict) {
  return dict.throwError;
};
var catchError = function(dict) {
  return dict.catchError;
};
var $$try = function(dictMonadError) {
  var catchError1 = catchError(dictMonadError);
  var Monad0 = dictMonadError.MonadThrow0().Monad0();
  var map23 = map(Monad0.Bind1().Apply0().Functor0());
  var pure11 = pure(Monad0.Applicative0());
  return function(a2) {
    return catchError1(map23(Right.create)(a2))(function($52) {
      return pure11(Left.create($52));
    });
  };
};

// output/Effect.Class/index.js
var monadEffectEffect = {
  liftEffect: /* @__PURE__ */ identity(categoryFn),
  Monad0: function() {
    return monadEffect;
  }
};
var liftEffect = function(dict) {
  return dict.liftEffect;
};

// output/Control.Parallel.Class/index.js
var sequential = function(dict) {
  return dict.sequential;
};
var parallel = function(dict) {
  return dict.parallel;
};

// output/Control.Parallel/index.js
var identity6 = /* @__PURE__ */ identity(categoryFn);
var parTraverse_ = function(dictParallel) {
  var sequential3 = sequential(dictParallel);
  var parallel4 = parallel(dictParallel);
  return function(dictApplicative) {
    var traverse_8 = traverse_(dictApplicative);
    return function(dictFoldable) {
      var traverse_14 = traverse_8(dictFoldable);
      return function(f) {
        var $51 = traverse_14(function($53) {
          return parallel4(f($53));
        });
        return function($52) {
          return sequential3($51($52));
        };
      };
    };
  };
};
var parSequence_ = function(dictParallel) {
  var parTraverse_1 = parTraverse_(dictParallel);
  return function(dictApplicative) {
    var parTraverse_2 = parTraverse_1(dictApplicative);
    return function(dictFoldable) {
      return parTraverse_2(dictFoldable)(identity6);
    };
  };
};

// output/Effect.Unsafe/foreign.js
var unsafePerformEffect = function(f) {
  return f();
};

// output/Partial.Unsafe/foreign.js
var _unsafePartial = function(f) {
  return f();
};

// output/Partial/foreign.js
var _crashWith = function(msg) {
  throw new Error(msg);
};

// output/Partial/index.js
var crashWith = function() {
  return _crashWith;
};

// output/Partial.Unsafe/index.js
var crashWith2 = /* @__PURE__ */ crashWith();
var unsafePartial = _unsafePartial;
var unsafeCrashWith = function(msg) {
  return unsafePartial(function() {
    return crashWith2(msg);
  });
};

// output/Effect.Aff/index.js
var $runtime_lazy2 = function(name15, moduleName, init4) {
  var state3 = 0;
  var val;
  return function(lineNumber) {
    if (state3 === 2) return val;
    if (state3 === 1) throw new ReferenceError(name15 + " was needed before it finished initializing (module " + moduleName + ", line " + lineNumber + ")", moduleName, lineNumber);
    state3 = 1;
    val = init4();
    state3 = 2;
    return val;
  };
};
var pure2 = /* @__PURE__ */ pure(applicativeEffect);
var $$void3 = /* @__PURE__ */ $$void(functorEffect);
var map5 = /* @__PURE__ */ map(functorEffect);
var Canceler = function(x4) {
  return x4;
};
var suspendAff = /* @__PURE__ */ _fork(false);
var functorParAff = {
  map: _parAffMap
};
var functorAff = {
  map: _map
};
var map1 = /* @__PURE__ */ map(functorAff);
var forkAff = /* @__PURE__ */ _fork(true);
var ffiUtil = /* @__PURE__ */ (function() {
  var unsafeFromRight = function(v) {
    if (v instanceof Right) {
      return v.value0;
    }
    ;
    if (v instanceof Left) {
      return unsafeCrashWith("unsafeFromRight: Left");
    }
    ;
    throw new Error("Failed pattern match at Effect.Aff (line 412, column 21 - line 414, column 54): " + [v.constructor.name]);
  };
  var unsafeFromLeft = function(v) {
    if (v instanceof Left) {
      return v.value0;
    }
    ;
    if (v instanceof Right) {
      return unsafeCrashWith("unsafeFromLeft: Right");
    }
    ;
    throw new Error("Failed pattern match at Effect.Aff (line 407, column 20 - line 409, column 55): " + [v.constructor.name]);
  };
  var isLeft = function(v) {
    if (v instanceof Left) {
      return true;
    }
    ;
    if (v instanceof Right) {
      return false;
    }
    ;
    throw new Error("Failed pattern match at Effect.Aff (line 402, column 12 - line 404, column 21): " + [v.constructor.name]);
  };
  return {
    isLeft,
    fromLeft: unsafeFromLeft,
    fromRight: unsafeFromRight,
    left: Left.create,
    right: Right.create
  };
})();
var makeFiber = function(aff) {
  return _makeFiber(ffiUtil, aff);
};
var launchAff = function(aff) {
  return function __do2() {
    var fiber = makeFiber(aff)();
    fiber.run();
    return fiber;
  };
};
var bracket = function(acquire) {
  return function(completed) {
    return generalBracket(acquire)({
      killed: $$const(completed),
      failed: $$const(completed),
      completed: $$const(completed)
    });
  };
};
var applyParAff = {
  apply: _parAffApply,
  Functor0: function() {
    return functorParAff;
  }
};
var monadAff = {
  Applicative0: function() {
    return applicativeAff;
  },
  Bind1: function() {
    return bindAff;
  }
};
var bindAff = {
  bind: _bind,
  Apply0: function() {
    return $lazy_applyAff(0);
  }
};
var applicativeAff = {
  pure: _pure,
  Apply0: function() {
    return $lazy_applyAff(0);
  }
};
var $lazy_applyAff = /* @__PURE__ */ $runtime_lazy2("applyAff", "Effect.Aff", function() {
  return {
    apply: ap(monadAff),
    Functor0: function() {
      return functorAff;
    }
  };
});
var applyAff = /* @__PURE__ */ $lazy_applyAff(73);
var pure22 = /* @__PURE__ */ pure(applicativeAff);
var bind1 = /* @__PURE__ */ bind(bindAff);
var bindFlipped3 = /* @__PURE__ */ bindFlipped(bindAff);
var $$finally = function(fin) {
  return function(a2) {
    return bracket(pure22(unit))($$const(fin))($$const(a2));
  };
};
var parallelAff = {
  parallel: unsafeCoerce2,
  sequential: _sequential,
  Apply0: function() {
    return applyAff;
  },
  Apply1: function() {
    return applyParAff;
  }
};
var parallel2 = /* @__PURE__ */ parallel(parallelAff);
var applicativeParAff = {
  pure: function($76) {
    return parallel2(pure22($76));
  },
  Apply0: function() {
    return applyParAff;
  }
};
var monadEffectAff = {
  liftEffect: _liftEffect,
  Monad0: function() {
    return monadAff;
  }
};
var liftEffect2 = /* @__PURE__ */ liftEffect(monadEffectAff);
var effectCanceler = function($77) {
  return Canceler($$const(liftEffect2($77)));
};
var joinFiber = function(v) {
  return makeAff(function(k) {
    return map5(effectCanceler)(v.join(k));
  });
};
var functorFiber = {
  map: function(f) {
    return function(t) {
      return unsafePerformEffect(makeFiber(map1(f)(joinFiber(t))));
    };
  }
};
var killFiber = function(e) {
  return function(v) {
    return bind1(liftEffect2(v.isSuspended))(function(suspended) {
      if (suspended) {
        return liftEffect2($$void3(v.kill(e, $$const(pure2(unit)))));
      }
      ;
      return makeAff(function(k) {
        return map5(effectCanceler)(v.kill(e, k));
      });
    });
  };
};
var monadThrowAff = {
  throwError: _throwError,
  Monad0: function() {
    return monadAff;
  }
};
var monadErrorAff = {
  catchError: _catchError,
  MonadThrow0: function() {
    return monadThrowAff;
  }
};
var $$try2 = /* @__PURE__ */ $$try(monadErrorAff);
var runAff = function(k) {
  return function(aff) {
    return launchAff(bindFlipped3(function($83) {
      return liftEffect2(k($83));
    })($$try2(aff)));
  };
};
var runAff_ = function(k) {
  return function(aff) {
    return $$void3(runAff(k)(aff));
  };
};
var monadRecAff = {
  tailRecM: function(k) {
    var go2 = function(a2) {
      return bind1(k(a2))(function(res) {
        if (res instanceof Done) {
          return pure22(res.value0);
        }
        ;
        if (res instanceof Loop) {
          return go2(res.value0);
        }
        ;
        throw new Error("Failed pattern match at Effect.Aff (line 104, column 7 - line 106, column 23): " + [res.constructor.name]);
      });
    };
    return go2;
  },
  Monad0: function() {
    return monadAff;
  }
};
var nonCanceler = /* @__PURE__ */ $$const(/* @__PURE__ */ pure22(unit));

// output/Effect.Aff.Class/index.js
var monadAffAff = {
  liftAff: /* @__PURE__ */ identity(categoryFn),
  MonadEffect0: function() {
    return monadEffectAff;
  }
};

// output/Effect.Console/foreign.js
var log2 = function(s) {
  return function() {
    console.log(s);
  };
};
var warn = function(s) {
  return function() {
    console.warn(s);
  };
};

// output/Web.DOM.ParentNode/foreign.js
var getEffProp = function(name15) {
  return function(node) {
    return function() {
      return node[name15];
    };
  };
};
var children = getEffProp("children");
var _firstElementChild = getEffProp("firstElementChild");
var _lastElementChild = getEffProp("lastElementChild");
var childElementCount = getEffProp("childElementCount");
function _querySelector(selector) {
  return function(node) {
    return function() {
      return node.querySelector(selector);
    };
  };
}
function querySelectorAll(selector) {
  return function(node) {
    return function() {
      return node.querySelectorAll(selector);
    };
  };
}

// output/Web.DOM.ParentNode/index.js
var map6 = /* @__PURE__ */ map(functorEffect);
var querySelector = function(qs) {
  var $2 = map6(toMaybe);
  var $3 = _querySelector(qs);
  return function($4) {
    return $2($3($4));
  };
};

// output/Web.Event.EventTarget/foreign.js
function eventListener(fn) {
  return function() {
    return function(event) {
      return fn(event)();
    };
  };
}
function addEventListener(type) {
  return function(listener) {
    return function(useCapture) {
      return function(target6) {
        return function() {
          return target6.addEventListener(type, listener, useCapture);
        };
      };
    };
  };
}
function removeEventListener(type) {
  return function(listener) {
    return function(useCapture) {
      return function(target6) {
        return function() {
          return target6.removeEventListener(type, listener, useCapture);
        };
      };
    };
  };
}

// output/Web.HTML/foreign.js
var windowImpl = function() {
  return window;
};

// output/Web.Internal.FFI/foreign.js
function _unsafeReadProtoTagged(nothing, just, name15, value12) {
  if (typeof window !== "undefined") {
    var ty = window[name15];
    if (ty != null && value12 instanceof ty) {
      return just(value12);
    }
  }
  var obj = value12;
  while (obj != null) {
    var proto = Object.getPrototypeOf(obj);
    var constructorName = proto.constructor.name;
    if (constructorName === name15) {
      return just(value12);
    } else if (constructorName === "Object") {
      return nothing;
    }
    obj = proto;
  }
  return nothing;
}

// output/Web.Internal.FFI/index.js
var unsafeReadProtoTagged = function(name15) {
  return function(value12) {
    return _unsafeReadProtoTagged(Nothing.value, Just.create, name15, value12);
  };
};

// output/Web.HTML.HTMLDocument/foreign.js
function _readyState(doc) {
  return doc.readyState;
}

// output/Web.HTML.HTMLDocument.ReadyState/index.js
var Loading = /* @__PURE__ */ (function() {
  function Loading2() {
  }
  ;
  Loading2.value = new Loading2();
  return Loading2;
})();
var Interactive = /* @__PURE__ */ (function() {
  function Interactive2() {
  }
  ;
  Interactive2.value = new Interactive2();
  return Interactive2;
})();
var Complete = /* @__PURE__ */ (function() {
  function Complete2() {
  }
  ;
  Complete2.value = new Complete2();
  return Complete2;
})();
var parse = function(v) {
  if (v === "loading") {
    return new Just(Loading.value);
  }
  ;
  if (v === "interactive") {
    return new Just(Interactive.value);
  }
  ;
  if (v === "complete") {
    return new Just(Complete.value);
  }
  ;
  return Nothing.value;
};

// output/Web.HTML.HTMLDocument/index.js
var map7 = /* @__PURE__ */ map(functorEffect);
var toParentNode = unsafeCoerce2;
var toDocument = unsafeCoerce2;
var readyState = function(doc) {
  return map7((function() {
    var $4 = fromMaybe(Loading.value);
    return function($5) {
      return $4(parse($5));
    };
  })())(function() {
    return _readyState(doc);
  });
};

// output/Web.HTML.HTMLElement/foreign.js
function _read(nothing, just, value12) {
  var tag = Object.prototype.toString.call(value12);
  if (tag.indexOf("[object HTML") === 0 && tag.indexOf("Element]") === tag.length - 8) {
    return just(value12);
  } else {
    return nothing;
  }
}

// output/Web.HTML.HTMLElement/index.js
var toNode = unsafeCoerce2;
var fromElement = function(x4) {
  return _read(Nothing.value, Just.create, x4);
};

// output/Web.HTML.Window/foreign.js
function document2(window2) {
  return function() {
    return window2.document;
  };
}

// output/Web.HTML.Window/index.js
var toEventTarget = unsafeCoerce2;

// output/Web.HTML.Event.EventTypes/index.js
var domcontentloaded = "DOMContentLoaded";

// output/Halogen.Aff.Util/index.js
var bind2 = /* @__PURE__ */ bind(bindAff);
var liftEffect3 = /* @__PURE__ */ liftEffect(monadEffectAff);
var bindFlipped4 = /* @__PURE__ */ bindFlipped(bindEffect);
var composeKleisliFlipped2 = /* @__PURE__ */ composeKleisliFlipped(bindEffect);
var pure3 = /* @__PURE__ */ pure(applicativeAff);
var bindFlipped1 = /* @__PURE__ */ bindFlipped(bindMaybe);
var pure1 = /* @__PURE__ */ pure(applicativeEffect);
var map8 = /* @__PURE__ */ map(functorEffect);
var discard2 = /* @__PURE__ */ discard(discardUnit);
var throwError2 = /* @__PURE__ */ throwError(monadThrowAff);
var selectElement = function(query2) {
  return bind2(liftEffect3(bindFlipped4(composeKleisliFlipped2((function() {
    var $16 = querySelector(query2);
    return function($17) {
      return $16(toParentNode($17));
    };
  })())(document2))(windowImpl)))(function(mel) {
    return pure3(bindFlipped1(fromElement)(mel));
  });
};
var runHalogenAff = /* @__PURE__ */ runAff_(/* @__PURE__ */ either(throwException)(/* @__PURE__ */ $$const(/* @__PURE__ */ pure1(unit))));
var awaitLoad = /* @__PURE__ */ makeAff(function(callback) {
  return function __do2() {
    var rs = bindFlipped4(readyState)(bindFlipped4(document2)(windowImpl))();
    if (rs instanceof Loading) {
      var et = map8(toEventTarget)(windowImpl)();
      var listener = eventListener(function(v) {
        return callback(new Right(unit));
      })();
      addEventListener(domcontentloaded)(listener)(false)(et)();
      return effectCanceler(removeEventListener(domcontentloaded)(listener)(false)(et));
    }
    ;
    callback(new Right(unit))();
    return nonCanceler;
  };
});
var awaitBody = /* @__PURE__ */ discard2(bindAff)(awaitLoad)(function() {
  return bind2(selectElement("body"))(function(body2) {
    return maybe(throwError2(error("Could not find body")))(pure3)(body2);
  });
});

// output/Data.Exists/index.js
var runExists = unsafeCoerce2;
var mkExists = unsafeCoerce2;

// output/Data.Coyoneda/index.js
var CoyonedaF = /* @__PURE__ */ (function() {
  function CoyonedaF2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  CoyonedaF2.create = function(value0) {
    return function(value1) {
      return new CoyonedaF2(value0, value1);
    };
  };
  return CoyonedaF2;
})();
var unCoyoneda = function(f) {
  return function(v) {
    return runExists(function(v1) {
      return f(v1.value0)(v1.value1);
    })(v);
  };
};
var coyoneda = function(k) {
  return function(fi) {
    return mkExists(new CoyonedaF(k, fi));
  };
};
var functorCoyoneda = {
  map: function(f) {
    return function(v) {
      return runExists(function(v1) {
        return coyoneda(function($180) {
          return f(v1.value0($180));
        })(v1.value1);
      })(v);
    };
  }
};
var liftCoyoneda = /* @__PURE__ */ coyoneda(/* @__PURE__ */ identity(categoryFn));

// output/Data.FoldableWithIndex/index.js
var foldr8 = /* @__PURE__ */ foldr(foldableArray);
var mapWithIndex2 = /* @__PURE__ */ mapWithIndex(functorWithIndexArray);
var foldl8 = /* @__PURE__ */ foldl(foldableArray);
var foldrWithIndex = function(dict) {
  return dict.foldrWithIndex;
};
var traverseWithIndex_ = function(dictApplicative) {
  var applySecond2 = applySecond(dictApplicative.Apply0());
  var pure11 = pure(dictApplicative);
  return function(dictFoldableWithIndex) {
    var foldrWithIndex1 = foldrWithIndex(dictFoldableWithIndex);
    return function(f) {
      return foldrWithIndex1(function(i2) {
        var $289 = f(i2);
        return function($290) {
          return applySecond2($289($290));
        };
      })(pure11(unit));
    };
  };
};
var foldlWithIndex = function(dict) {
  return dict.foldlWithIndex;
};
var foldMapWithIndexDefaultR = function(dictFoldableWithIndex) {
  var foldrWithIndex1 = foldrWithIndex(dictFoldableWithIndex);
  return function(dictMonoid) {
    var append9 = append(dictMonoid.Semigroup0());
    var mempty2 = mempty(dictMonoid);
    return function(f) {
      return foldrWithIndex1(function(i2) {
        return function(x4) {
          return function(acc) {
            return append9(f(i2)(x4))(acc);
          };
        };
      })(mempty2);
    };
  };
};
var foldableWithIndexArray = {
  foldrWithIndex: function(f) {
    return function(z) {
      var $291 = foldr8(function(v) {
        return function(y4) {
          return f(v.value0)(v.value1)(y4);
        };
      })(z);
      var $292 = mapWithIndex2(Tuple.create);
      return function($293) {
        return $291($292($293));
      };
    };
  },
  foldlWithIndex: function(f) {
    return function(z) {
      var $294 = foldl8(function(y4) {
        return function(v) {
          return f(v.value0)(y4)(v.value1);
        };
      })(z);
      var $295 = mapWithIndex2(Tuple.create);
      return function($296) {
        return $294($295($296));
      };
    };
  },
  foldMapWithIndex: function(dictMonoid) {
    return foldMapWithIndexDefaultR(foldableWithIndexArray)(dictMonoid);
  },
  Foldable0: function() {
    return foldableArray;
  }
};

// output/Data.TraversableWithIndex/index.js
var traverseWithIndexDefault = function(dictTraversableWithIndex) {
  var sequence2 = sequence(dictTraversableWithIndex.Traversable2());
  var mapWithIndex4 = mapWithIndex(dictTraversableWithIndex.FunctorWithIndex0());
  return function(dictApplicative) {
    var sequence12 = sequence2(dictApplicative);
    return function(f) {
      var $174 = mapWithIndex4(f);
      return function($175) {
        return sequence12($174($175));
      };
    };
  };
};
var traverseWithIndex = function(dict) {
  return dict.traverseWithIndex;
};
var traversableWithIndexArray = {
  traverseWithIndex: function(dictApplicative) {
    return traverseWithIndexDefault(traversableWithIndexArray)(dictApplicative);
  },
  FunctorWithIndex0: function() {
    return functorWithIndexArray;
  },
  FoldableWithIndex1: function() {
    return foldableWithIndexArray;
  },
  Traversable2: function() {
    return traversableArray;
  }
};

// output/Data.NonEmpty/index.js
var NonEmpty = /* @__PURE__ */ (function() {
  function NonEmpty2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  NonEmpty2.create = function(value0) {
    return function(value1) {
      return new NonEmpty2(value0, value1);
    };
  };
  return NonEmpty2;
})();
var singleton3 = function(dictPlus) {
  var empty8 = empty(dictPlus);
  return function(a2) {
    return new NonEmpty(a2, empty8);
  };
};

// output/Data.List.Types/index.js
var Nil = /* @__PURE__ */ (function() {
  function Nil2() {
  }
  ;
  Nil2.value = new Nil2();
  return Nil2;
})();
var Cons = /* @__PURE__ */ (function() {
  function Cons2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  Cons2.create = function(value0) {
    return function(value1) {
      return new Cons2(value0, value1);
    };
  };
  return Cons2;
})();
var NonEmptyList = function(x4) {
  return x4;
};
var listMap = function(f) {
  var chunkedRevMap = function($copy_v) {
    return function($copy_v1) {
      var $tco_var_v = $copy_v;
      var $tco_done = false;
      var $tco_result;
      function $tco_loop(v, v1) {
        if (v1 instanceof Cons && (v1.value1 instanceof Cons && v1.value1.value1 instanceof Cons)) {
          $tco_var_v = new Cons(v1, v);
          $copy_v1 = v1.value1.value1.value1;
          return;
        }
        ;
        var unrolledMap = function(v2) {
          if (v2 instanceof Cons && (v2.value1 instanceof Cons && v2.value1.value1 instanceof Nil)) {
            return new Cons(f(v2.value0), new Cons(f(v2.value1.value0), Nil.value));
          }
          ;
          if (v2 instanceof Cons && v2.value1 instanceof Nil) {
            return new Cons(f(v2.value0), Nil.value);
          }
          ;
          return Nil.value;
        };
        var reverseUnrolledMap = function($copy_v2) {
          return function($copy_v3) {
            var $tco_var_v2 = $copy_v2;
            var $tco_done1 = false;
            var $tco_result2;
            function $tco_loop2(v2, v3) {
              if (v2 instanceof Cons && (v2.value0 instanceof Cons && (v2.value0.value1 instanceof Cons && v2.value0.value1.value1 instanceof Cons))) {
                $tco_var_v2 = v2.value1;
                $copy_v3 = new Cons(f(v2.value0.value0), new Cons(f(v2.value0.value1.value0), new Cons(f(v2.value0.value1.value1.value0), v3)));
                return;
              }
              ;
              $tco_done1 = true;
              return v3;
            }
            ;
            while (!$tco_done1) {
              $tco_result2 = $tco_loop2($tco_var_v2, $copy_v3);
            }
            ;
            return $tco_result2;
          };
        };
        $tco_done = true;
        return reverseUnrolledMap(v)(unrolledMap(v1));
      }
      ;
      while (!$tco_done) {
        $tco_result = $tco_loop($tco_var_v, $copy_v1);
      }
      ;
      return $tco_result;
    };
  };
  return chunkedRevMap(Nil.value);
};
var functorList = {
  map: listMap
};
var foldableList = {
  foldr: function(f) {
    return function(b10) {
      var rev3 = (function() {
        var go2 = function($copy_v) {
          return function($copy_v1) {
            var $tco_var_v = $copy_v;
            var $tco_done = false;
            var $tco_result;
            function $tco_loop(v, v1) {
              if (v1 instanceof Nil) {
                $tco_done = true;
                return v;
              }
              ;
              if (v1 instanceof Cons) {
                $tco_var_v = new Cons(v1.value0, v);
                $copy_v1 = v1.value1;
                return;
              }
              ;
              throw new Error("Failed pattern match at Data.List.Types (line 107, column 7 - line 107, column 23): " + [v.constructor.name, v1.constructor.name]);
            }
            ;
            while (!$tco_done) {
              $tco_result = $tco_loop($tco_var_v, $copy_v1);
            }
            ;
            return $tco_result;
          };
        };
        return go2(Nil.value);
      })();
      var $284 = foldl(foldableList)(flip(f))(b10);
      return function($285) {
        return $284(rev3($285));
      };
    };
  },
  foldl: function(f) {
    var go2 = function($copy_b) {
      return function($copy_v) {
        var $tco_var_b = $copy_b;
        var $tco_done1 = false;
        var $tco_result;
        function $tco_loop(b10, v) {
          if (v instanceof Nil) {
            $tco_done1 = true;
            return b10;
          }
          ;
          if (v instanceof Cons) {
            $tco_var_b = f(b10)(v.value0);
            $copy_v = v.value1;
            return;
          }
          ;
          throw new Error("Failed pattern match at Data.List.Types (line 111, column 12 - line 113, column 30): " + [v.constructor.name]);
        }
        ;
        while (!$tco_done1) {
          $tco_result = $tco_loop($tco_var_b, $copy_v);
        }
        ;
        return $tco_result;
      };
    };
    return go2;
  },
  foldMap: function(dictMonoid) {
    var append22 = append(dictMonoid.Semigroup0());
    var mempty2 = mempty(dictMonoid);
    return function(f) {
      return foldl(foldableList)(function(acc) {
        var $286 = append22(acc);
        return function($287) {
          return $286(f($287));
        };
      })(mempty2);
    };
  }
};
var foldr2 = /* @__PURE__ */ foldr(foldableList);
var semigroupList = {
  append: function(xs) {
    return function(ys) {
      return foldr2(Cons.create)(ys)(xs);
    };
  }
};
var append1 = /* @__PURE__ */ append(semigroupList);
var altList = {
  alt: append1,
  Functor0: function() {
    return functorList;
  }
};
var plusList = /* @__PURE__ */ (function() {
  return {
    empty: Nil.value,
    Alt0: function() {
      return altList;
    }
  };
})();

// output/Data.Map.Internal/index.js
var $runtime_lazy3 = function(name15, moduleName, init4) {
  var state3 = 0;
  var val;
  return function(lineNumber) {
    if (state3 === 2) return val;
    if (state3 === 1) throw new ReferenceError(name15 + " was needed before it finished initializing (module " + moduleName + ", line " + lineNumber + ")", moduleName, lineNumber);
    state3 = 1;
    val = init4();
    state3 = 2;
    return val;
  };
};
var Leaf = /* @__PURE__ */ (function() {
  function Leaf2() {
  }
  ;
  Leaf2.value = new Leaf2();
  return Leaf2;
})();
var Node = /* @__PURE__ */ (function() {
  function Node3(value0, value1, value22, value32, value42, value52) {
    this.value0 = value0;
    this.value1 = value1;
    this.value2 = value22;
    this.value3 = value32;
    this.value4 = value42;
    this.value5 = value52;
  }
  ;
  Node3.create = function(value0) {
    return function(value1) {
      return function(value22) {
        return function(value32) {
          return function(value42) {
            return function(value52) {
              return new Node3(value0, value1, value22, value32, value42, value52);
            };
          };
        };
      };
    };
  };
  return Node3;
})();
var Split = /* @__PURE__ */ (function() {
  function Split2(value0, value1, value22) {
    this.value0 = value0;
    this.value1 = value1;
    this.value2 = value22;
  }
  ;
  Split2.create = function(value0) {
    return function(value1) {
      return function(value22) {
        return new Split2(value0, value1, value22);
      };
    };
  };
  return Split2;
})();
var SplitLast = /* @__PURE__ */ (function() {
  function SplitLast2(value0, value1, value22) {
    this.value0 = value0;
    this.value1 = value1;
    this.value2 = value22;
  }
  ;
  SplitLast2.create = function(value0) {
    return function(value1) {
      return function(value22) {
        return new SplitLast2(value0, value1, value22);
      };
    };
  };
  return SplitLast2;
})();
var unsafeNode = function(k, v, l, r) {
  if (l instanceof Leaf) {
    if (r instanceof Leaf) {
      return new Node(1, 1, k, v, l, r);
    }
    ;
    if (r instanceof Node) {
      return new Node(1 + r.value0 | 0, 1 + r.value1 | 0, k, v, l, r);
    }
    ;
    throw new Error("Failed pattern match at Data.Map.Internal (line 702, column 5 - line 706, column 39): " + [r.constructor.name]);
  }
  ;
  if (l instanceof Node) {
    if (r instanceof Leaf) {
      return new Node(1 + l.value0 | 0, 1 + l.value1 | 0, k, v, l, r);
    }
    ;
    if (r instanceof Node) {
      return new Node(1 + (function() {
        var $280 = l.value0 > r.value0;
        if ($280) {
          return l.value0;
        }
        ;
        return r.value0;
      })() | 0, (1 + l.value1 | 0) + r.value1 | 0, k, v, l, r);
    }
    ;
    throw new Error("Failed pattern match at Data.Map.Internal (line 708, column 5 - line 712, column 68): " + [r.constructor.name]);
  }
  ;
  throw new Error("Failed pattern match at Data.Map.Internal (line 700, column 32 - line 712, column 68): " + [l.constructor.name]);
};
var singleton4 = function(k) {
  return function(v) {
    return new Node(1, 1, k, v, Leaf.value, Leaf.value);
  };
};
var unsafeBalancedNode = /* @__PURE__ */ (function() {
  var height8 = function(v) {
    if (v instanceof Leaf) {
      return 0;
    }
    ;
    if (v instanceof Node) {
      return v.value0;
    }
    ;
    throw new Error("Failed pattern match at Data.Map.Internal (line 757, column 12 - line 759, column 26): " + [v.constructor.name]);
  };
  var rotateLeft = function(k, v, l, rk, rv, rl, rr) {
    if (rl instanceof Node && rl.value0 > height8(rr)) {
      return unsafeNode(rl.value2, rl.value3, unsafeNode(k, v, l, rl.value4), unsafeNode(rk, rv, rl.value5, rr));
    }
    ;
    return unsafeNode(rk, rv, unsafeNode(k, v, l, rl), rr);
  };
  var rotateRight = function(k, v, lk, lv, ll, lr, r) {
    if (lr instanceof Node && height8(ll) <= lr.value0) {
      return unsafeNode(lr.value2, lr.value3, unsafeNode(lk, lv, ll, lr.value4), unsafeNode(k, v, lr.value5, r));
    }
    ;
    return unsafeNode(lk, lv, ll, unsafeNode(k, v, lr, r));
  };
  return function(k, v, l, r) {
    if (l instanceof Leaf) {
      if (r instanceof Leaf) {
        return singleton4(k)(v);
      }
      ;
      if (r instanceof Node && r.value0 > 1) {
        return rotateLeft(k, v, l, r.value2, r.value3, r.value4, r.value5);
      }
      ;
      return unsafeNode(k, v, l, r);
    }
    ;
    if (l instanceof Node) {
      if (r instanceof Node) {
        if (r.value0 > (l.value0 + 1 | 0)) {
          return rotateLeft(k, v, l, r.value2, r.value3, r.value4, r.value5);
        }
        ;
        if (l.value0 > (r.value0 + 1 | 0)) {
          return rotateRight(k, v, l.value2, l.value3, l.value4, l.value5, r);
        }
        ;
      }
      ;
      if (r instanceof Leaf && l.value0 > 1) {
        return rotateRight(k, v, l.value2, l.value3, l.value4, l.value5, r);
      }
      ;
      return unsafeNode(k, v, l, r);
    }
    ;
    throw new Error("Failed pattern match at Data.Map.Internal (line 717, column 40 - line 738, column 34): " + [l.constructor.name]);
  };
})();
var $lazy_unsafeSplit = /* @__PURE__ */ $runtime_lazy3("unsafeSplit", "Data.Map.Internal", function() {
  return function(comp, k, m) {
    if (m instanceof Leaf) {
      return new Split(Nothing.value, Leaf.value, Leaf.value);
    }
    ;
    if (m instanceof Node) {
      var v = comp(k)(m.value2);
      if (v instanceof LT) {
        var v1 = $lazy_unsafeSplit(793)(comp, k, m.value4);
        return new Split(v1.value0, v1.value1, unsafeBalancedNode(m.value2, m.value3, v1.value2, m.value5));
      }
      ;
      if (v instanceof GT) {
        var v1 = $lazy_unsafeSplit(796)(comp, k, m.value5);
        return new Split(v1.value0, unsafeBalancedNode(m.value2, m.value3, m.value4, v1.value1), v1.value2);
      }
      ;
      if (v instanceof EQ) {
        return new Split(new Just(m.value3), m.value4, m.value5);
      }
      ;
      throw new Error("Failed pattern match at Data.Map.Internal (line 791, column 5 - line 799, column 30): " + [v.constructor.name]);
    }
    ;
    throw new Error("Failed pattern match at Data.Map.Internal (line 787, column 34 - line 799, column 30): " + [m.constructor.name]);
  };
});
var unsafeSplit = /* @__PURE__ */ $lazy_unsafeSplit(786);
var $lazy_unsafeSplitLast = /* @__PURE__ */ $runtime_lazy3("unsafeSplitLast", "Data.Map.Internal", function() {
  return function(k, v, l, r) {
    if (r instanceof Leaf) {
      return new SplitLast(k, v, l);
    }
    ;
    if (r instanceof Node) {
      var v1 = $lazy_unsafeSplitLast(779)(r.value2, r.value3, r.value4, r.value5);
      return new SplitLast(v1.value0, v1.value1, unsafeBalancedNode(k, v, l, v1.value2));
    }
    ;
    throw new Error("Failed pattern match at Data.Map.Internal (line 776, column 37 - line 780, column 57): " + [r.constructor.name]);
  };
});
var unsafeSplitLast = /* @__PURE__ */ $lazy_unsafeSplitLast(775);
var unsafeJoinNodes = function(v, v1) {
  if (v instanceof Leaf) {
    return v1;
  }
  ;
  if (v instanceof Node) {
    var v2 = unsafeSplitLast(v.value2, v.value3, v.value4, v.value5);
    return unsafeBalancedNode(v2.value0, v2.value1, v2.value2, v1);
  }
  ;
  throw new Error("Failed pattern match at Data.Map.Internal (line 764, column 25 - line 768, column 38): " + [v.constructor.name, v1.constructor.name]);
};
var $lazy_unsafeUnionWith = /* @__PURE__ */ $runtime_lazy3("unsafeUnionWith", "Data.Map.Internal", function() {
  return function(comp, app, l, r) {
    if (l instanceof Leaf) {
      return r;
    }
    ;
    if (r instanceof Leaf) {
      return l;
    }
    ;
    if (r instanceof Node) {
      var v = unsafeSplit(comp, r.value2, l);
      var l$prime = $lazy_unsafeUnionWith(809)(comp, app, v.value1, r.value4);
      var r$prime = $lazy_unsafeUnionWith(810)(comp, app, v.value2, r.value5);
      if (v.value0 instanceof Just) {
        return unsafeBalancedNode(r.value2, app(v.value0.value0)(r.value3), l$prime, r$prime);
      }
      ;
      if (v.value0 instanceof Nothing) {
        return unsafeBalancedNode(r.value2, r.value3, l$prime, r$prime);
      }
      ;
      throw new Error("Failed pattern match at Data.Map.Internal (line 811, column 5 - line 815, column 46): " + [v.value0.constructor.name]);
    }
    ;
    throw new Error("Failed pattern match at Data.Map.Internal (line 804, column 42 - line 815, column 46): " + [l.constructor.name, r.constructor.name]);
  };
});
var unsafeUnionWith = /* @__PURE__ */ $lazy_unsafeUnionWith(803);
var unionWith = function(dictOrd) {
  var compare3 = compare(dictOrd);
  return function(app) {
    return function(m1) {
      return function(m2) {
        return unsafeUnionWith(compare3, app, m1, m2);
      };
    };
  };
};
var union = function(dictOrd) {
  return unionWith(dictOrd)($$const);
};
var lookup = function(dictOrd) {
  var compare3 = compare(dictOrd);
  return function(k) {
    var go2 = function($copy_v) {
      var $tco_done = false;
      var $tco_result;
      function $tco_loop(v) {
        if (v instanceof Leaf) {
          $tco_done = true;
          return Nothing.value;
        }
        ;
        if (v instanceof Node) {
          var v1 = compare3(k)(v.value2);
          if (v1 instanceof LT) {
            $copy_v = v.value4;
            return;
          }
          ;
          if (v1 instanceof GT) {
            $copy_v = v.value5;
            return;
          }
          ;
          if (v1 instanceof EQ) {
            $tco_done = true;
            return new Just(v.value3);
          }
          ;
          throw new Error("Failed pattern match at Data.Map.Internal (line 283, column 7 - line 286, column 22): " + [v1.constructor.name]);
        }
        ;
        throw new Error("Failed pattern match at Data.Map.Internal (line 280, column 8 - line 286, column 22): " + [v.constructor.name]);
      }
      ;
      while (!$tco_done) {
        $tco_result = $tco_loop($copy_v);
      }
      ;
      return $tco_result;
    };
    return go2;
  };
};
var insert = function(dictOrd) {
  var compare3 = compare(dictOrd);
  return function(k) {
    return function(v) {
      var go2 = function(v1) {
        if (v1 instanceof Leaf) {
          return singleton4(k)(v);
        }
        ;
        if (v1 instanceof Node) {
          var v2 = compare3(k)(v1.value2);
          if (v2 instanceof LT) {
            return unsafeBalancedNode(v1.value2, v1.value3, go2(v1.value4), v1.value5);
          }
          ;
          if (v2 instanceof GT) {
            return unsafeBalancedNode(v1.value2, v1.value3, v1.value4, go2(v1.value5));
          }
          ;
          if (v2 instanceof EQ) {
            return new Node(v1.value0, v1.value1, k, v, v1.value4, v1.value5);
          }
          ;
          throw new Error("Failed pattern match at Data.Map.Internal (line 471, column 7 - line 474, column 35): " + [v2.constructor.name]);
        }
        ;
        throw new Error("Failed pattern match at Data.Map.Internal (line 468, column 8 - line 474, column 35): " + [v1.constructor.name]);
      };
      return go2;
    };
  };
};
var functorMap = {
  map: function(f) {
    var go2 = function(v) {
      if (v instanceof Leaf) {
        return Leaf.value;
      }
      ;
      if (v instanceof Node) {
        return new Node(v.value0, v.value1, v.value2, f(v.value3), go2(v.value4), go2(v.value5));
      }
      ;
      throw new Error("Failed pattern match at Data.Map.Internal (line 147, column 10 - line 150, column 39): " + [v.constructor.name]);
    };
    return go2;
  }
};
var foldableMap = {
  foldr: function(f) {
    return function(z) {
      var $lazy_go = $runtime_lazy3("go", "Data.Map.Internal", function() {
        return function(m$prime, z$prime) {
          if (m$prime instanceof Leaf) {
            return z$prime;
          }
          ;
          if (m$prime instanceof Node) {
            return $lazy_go(172)(m$prime.value4, f(m$prime.value3)($lazy_go(172)(m$prime.value5, z$prime)));
          }
          ;
          throw new Error("Failed pattern match at Data.Map.Internal (line 169, column 26 - line 172, column 43): " + [m$prime.constructor.name]);
        };
      });
      var go2 = $lazy_go(169);
      return function(m) {
        return go2(m, z);
      };
    };
  },
  foldl: function(f) {
    return function(z) {
      var $lazy_go = $runtime_lazy3("go", "Data.Map.Internal", function() {
        return function(z$prime, m$prime) {
          if (m$prime instanceof Leaf) {
            return z$prime;
          }
          ;
          if (m$prime instanceof Node) {
            return $lazy_go(178)(f($lazy_go(178)(z$prime, m$prime.value4))(m$prime.value3), m$prime.value5);
          }
          ;
          throw new Error("Failed pattern match at Data.Map.Internal (line 175, column 26 - line 178, column 43): " + [m$prime.constructor.name]);
        };
      });
      var go2 = $lazy_go(175);
      return function(m) {
        return go2(z, m);
      };
    };
  },
  foldMap: function(dictMonoid) {
    var mempty2 = mempty(dictMonoid);
    var append13 = append(dictMonoid.Semigroup0());
    return function(f) {
      var go2 = function(v) {
        if (v instanceof Leaf) {
          return mempty2;
        }
        ;
        if (v instanceof Node) {
          return append13(go2(v.value4))(append13(f(v.value3))(go2(v.value5)));
        }
        ;
        throw new Error("Failed pattern match at Data.Map.Internal (line 181, column 10 - line 184, column 28): " + [v.constructor.name]);
      };
      return go2;
    };
  }
};
var empty2 = /* @__PURE__ */ (function() {
  return Leaf.value;
})();
var $$delete = function(dictOrd) {
  var compare3 = compare(dictOrd);
  return function(k) {
    var go2 = function(v) {
      if (v instanceof Leaf) {
        return Leaf.value;
      }
      ;
      if (v instanceof Node) {
        var v1 = compare3(k)(v.value2);
        if (v1 instanceof LT) {
          return unsafeBalancedNode(v.value2, v.value3, go2(v.value4), v.value5);
        }
        ;
        if (v1 instanceof GT) {
          return unsafeBalancedNode(v.value2, v.value3, v.value4, go2(v.value5));
        }
        ;
        if (v1 instanceof EQ) {
          return unsafeJoinNodes(v.value4, v.value5);
        }
        ;
        throw new Error("Failed pattern match at Data.Map.Internal (line 498, column 7 - line 501, column 43): " + [v1.constructor.name]);
      }
      ;
      throw new Error("Failed pattern match at Data.Map.Internal (line 495, column 8 - line 501, column 43): " + [v.constructor.name]);
    };
    return go2;
  };
};
var alter = function(dictOrd) {
  var compare3 = compare(dictOrd);
  return function(f) {
    return function(k) {
      return function(m) {
        var v = unsafeSplit(compare3, k, m);
        var v2 = f(v.value0);
        if (v2 instanceof Nothing) {
          return unsafeJoinNodes(v.value1, v.value2);
        }
        ;
        if (v2 instanceof Just) {
          return unsafeBalancedNode(k, v2.value0, v.value1, v.value2);
        }
        ;
        throw new Error("Failed pattern match at Data.Map.Internal (line 514, column 3 - line 518, column 41): " + [v2.constructor.name]);
      };
    };
  };
};

// output/Halogen.Data.Slot/index.js
var foreachSlot = function(dictApplicative) {
  var traverse_8 = traverse_(dictApplicative)(foldableMap);
  return function(v) {
    return function(k) {
      return traverse_8(function($54) {
        return k($54);
      })(v);
    };
  };
};
var empty3 = empty2;

// output/Halogen.Query.Input/index.js
var RefUpdate = /* @__PURE__ */ (function() {
  function RefUpdate2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  RefUpdate2.create = function(value0) {
    return function(value1) {
      return new RefUpdate2(value0, value1);
    };
  };
  return RefUpdate2;
})();
var Action = /* @__PURE__ */ (function() {
  function Action3(value0) {
    this.value0 = value0;
  }
  ;
  Action3.create = function(value0) {
    return new Action3(value0);
  };
  return Action3;
})();

// output/Halogen.VDom.Machine/index.js
var Step = /* @__PURE__ */ (function() {
  function Step3(value0, value1, value22, value32) {
    this.value0 = value0;
    this.value1 = value1;
    this.value2 = value22;
    this.value3 = value32;
  }
  ;
  Step3.create = function(value0) {
    return function(value1) {
      return function(value22) {
        return function(value32) {
          return new Step3(value0, value1, value22, value32);
        };
      };
    };
  };
  return Step3;
})();
var unStep = unsafeCoerce2;
var step2 = function(v, a2) {
  return v.value2(v.value1, a2);
};
var mkStep = unsafeCoerce2;
var halt = function(v) {
  return v.value3(v.value1);
};
var extract2 = /* @__PURE__ */ unStep(function(v) {
  return v.value0;
});

// output/Halogen.VDom.Types/index.js
var map9 = /* @__PURE__ */ map(functorArray);
var map12 = /* @__PURE__ */ map(functorTuple);
var Text = /* @__PURE__ */ (function() {
  function Text3(value0) {
    this.value0 = value0;
  }
  ;
  Text3.create = function(value0) {
    return new Text3(value0);
  };
  return Text3;
})();
var Elem = /* @__PURE__ */ (function() {
  function Elem2(value0, value1, value22, value32) {
    this.value0 = value0;
    this.value1 = value1;
    this.value2 = value22;
    this.value3 = value32;
  }
  ;
  Elem2.create = function(value0) {
    return function(value1) {
      return function(value22) {
        return function(value32) {
          return new Elem2(value0, value1, value22, value32);
        };
      };
    };
  };
  return Elem2;
})();
var Keyed = /* @__PURE__ */ (function() {
  function Keyed2(value0, value1, value22, value32) {
    this.value0 = value0;
    this.value1 = value1;
    this.value2 = value22;
    this.value3 = value32;
  }
  ;
  Keyed2.create = function(value0) {
    return function(value1) {
      return function(value22) {
        return function(value32) {
          return new Keyed2(value0, value1, value22, value32);
        };
      };
    };
  };
  return Keyed2;
})();
var Widget = /* @__PURE__ */ (function() {
  function Widget2(value0) {
    this.value0 = value0;
  }
  ;
  Widget2.create = function(value0) {
    return new Widget2(value0);
  };
  return Widget2;
})();
var Grafted = /* @__PURE__ */ (function() {
  function Grafted2(value0) {
    this.value0 = value0;
  }
  ;
  Grafted2.create = function(value0) {
    return new Grafted2(value0);
  };
  return Grafted2;
})();
var Graft = /* @__PURE__ */ (function() {
  function Graft2(value0, value1, value22) {
    this.value0 = value0;
    this.value1 = value1;
    this.value2 = value22;
  }
  ;
  Graft2.create = function(value0) {
    return function(value1) {
      return function(value22) {
        return new Graft2(value0, value1, value22);
      };
    };
  };
  return Graft2;
})();
var unGraft = function(f) {
  return function($61) {
    return f($61);
  };
};
var graft = unsafeCoerce2;
var bifunctorGraft = {
  bimap: function(f) {
    return function(g) {
      return unGraft(function(v) {
        return graft(new Graft(function($63) {
          return f(v.value0($63));
        }, function($64) {
          return g(v.value1($64));
        }, v.value2));
      });
    };
  }
};
var bimap2 = /* @__PURE__ */ bimap(bifunctorGraft);
var runGraft = /* @__PURE__ */ unGraft(function(v) {
  var go2 = function(v2) {
    if (v2 instanceof Text) {
      return new Text(v2.value0);
    }
    ;
    if (v2 instanceof Elem) {
      return new Elem(v2.value0, v2.value1, v.value0(v2.value2), map9(go2)(v2.value3));
    }
    ;
    if (v2 instanceof Keyed) {
      return new Keyed(v2.value0, v2.value1, v.value0(v2.value2), map9(map12(go2))(v2.value3));
    }
    ;
    if (v2 instanceof Widget) {
      return new Widget(v.value1(v2.value0));
    }
    ;
    if (v2 instanceof Grafted) {
      return new Grafted(bimap2(v.value0)(v.value1)(v2.value0));
    }
    ;
    throw new Error("Failed pattern match at Halogen.VDom.Types (line 86, column 7 - line 86, column 27): " + [v2.constructor.name]);
  };
  return go2(v.value2);
});

// output/Halogen.VDom.Util/foreign.js
function unsafeGetAny(key, obj) {
  return obj[key];
}
function unsafeHasAny(key, obj) {
  return obj.hasOwnProperty(key);
}
function unsafeSetAny(key, val, obj) {
  obj[key] = val;
}
function forE2(a2, f) {
  var b10 = [];
  for (var i2 = 0; i2 < a2.length; i2++) {
    b10.push(f(i2, a2[i2]));
  }
  return b10;
}
function forEachE(a2, f) {
  for (var i2 = 0; i2 < a2.length; i2++) {
    f(a2[i2]);
  }
}
function forInE(o, f) {
  var ks = Object.keys(o);
  for (var i2 = 0; i2 < ks.length; i2++) {
    var k = ks[i2];
    f(k, o[k]);
  }
}
function diffWithIxE(a1, a2, f1, f2, f3) {
  var a3 = [];
  var l1 = a1.length;
  var l2 = a2.length;
  var i2 = 0;
  while (1) {
    if (i2 < l1) {
      if (i2 < l2) {
        a3.push(f1(i2, a1[i2], a2[i2]));
      } else {
        f2(i2, a1[i2]);
      }
    } else if (i2 < l2) {
      a3.push(f3(i2, a2[i2]));
    } else {
      break;
    }
    i2++;
  }
  return a3;
}
function strMapWithIxE(as, fk, f) {
  var o = {};
  for (var i2 = 0; i2 < as.length; i2++) {
    var a2 = as[i2];
    var k = fk(a2);
    o[k] = f(k, i2, a2);
  }
  return o;
}
function diffWithKeyAndIxE(o1, as, fk, f1, f2, f3) {
  var o2 = {};
  for (var i2 = 0; i2 < as.length; i2++) {
    var a2 = as[i2];
    var k = fk(a2);
    if (o1.hasOwnProperty(k)) {
      o2[k] = f1(k, i2, o1[k], a2);
    } else {
      o2[k] = f3(k, i2, a2);
    }
  }
  for (var k in o1) {
    if (k in o2) {
      continue;
    }
    f2(k, o1[k]);
  }
  return o2;
}
function refEq2(a2, b10) {
  return a2 === b10;
}
function createTextNode(s, doc) {
  return doc.createTextNode(s);
}
function setTextContent(s, n) {
  n.textContent = s;
}
function createElement(ns, name15, doc) {
  if (ns != null) {
    return doc.createElementNS(ns, name15);
  } else {
    return doc.createElement(name15);
  }
}
function insertChildIx(i2, a2, b10) {
  var n = b10.childNodes.item(i2) || null;
  if (n !== a2) {
    b10.insertBefore(a2, n);
  }
}
function removeChild(a2, b10) {
  if (b10 && a2.parentNode === b10) {
    b10.removeChild(a2);
  }
}
function parentNode(a2) {
  return a2.parentNode;
}
function setAttribute(ns, attr5, val, el) {
  if (ns != null) {
    el.setAttributeNS(ns, attr5, val);
  } else {
    el.setAttribute(attr5, val);
  }
}
function removeAttribute(ns, attr5, el) {
  if (ns != null) {
    el.removeAttributeNS(ns, attr5);
  } else {
    el.removeAttribute(attr5);
  }
}
function hasAttribute(ns, attr5, el) {
  if (ns != null) {
    return el.hasAttributeNS(ns, attr5);
  } else {
    return el.hasAttribute(attr5);
  }
}
function addEventListener2(ev, listener, el) {
  el.addEventListener(ev, listener, false);
}
function removeEventListener2(ev, listener, el) {
  el.removeEventListener(ev, listener, false);
}
var jsUndefined = void 0;

// output/Foreign.Object.ST/foreign.js
var newImpl = function() {
  return {};
};

// output/Halogen.VDom.Util/index.js
var unsafeLookup = unsafeGetAny;
var unsafeFreeze2 = unsafeCoerce2;
var pokeMutMap = unsafeSetAny;
var newMutMap = newImpl;

// output/Web.DOM.Element/foreign.js
var getProp = function(name15) {
  return function(doctype) {
    return doctype[name15];
  };
};
var _namespaceURI = getProp("namespaceURI");
var _prefix = getProp("prefix");
var localName = getProp("localName");
var tagName = getProp("tagName");
function setAttribute2(name15) {
  return function(value12) {
    return function(element3) {
      return function() {
        element3.setAttribute(name15, value12);
      };
    };
  };
}

// output/Web.DOM.Element/index.js
var toParentNode2 = unsafeCoerce2;
var toNode2 = unsafeCoerce2;
var fromNode = /* @__PURE__ */ unsafeReadProtoTagged("Element");

// output/Halogen.VDom.DOM/index.js
var $runtime_lazy4 = function(name15, moduleName, init4) {
  var state3 = 0;
  var val;
  return function(lineNumber) {
    if (state3 === 2) return val;
    if (state3 === 1) throw new ReferenceError(name15 + " was needed before it finished initializing (module " + moduleName + ", line " + lineNumber + ")", moduleName, lineNumber);
    state3 = 1;
    val = init4();
    state3 = 2;
    return val;
  };
};
var haltWidget = function(v) {
  return halt(v.widget);
};
var $lazy_patchWidget = /* @__PURE__ */ $runtime_lazy4("patchWidget", "Halogen.VDom.DOM", function() {
  return function(state3, vdom) {
    if (vdom instanceof Grafted) {
      return $lazy_patchWidget(291)(state3, runGraft(vdom.value0));
    }
    ;
    if (vdom instanceof Widget) {
      var res = step2(state3.widget, vdom.value0);
      var res$prime = unStep(function(v) {
        return mkStep(new Step(v.value0, {
          build: state3.build,
          widget: res
        }, $lazy_patchWidget(296), haltWidget));
      })(res);
      return res$prime;
    }
    ;
    haltWidget(state3);
    return state3.build(vdom);
  };
});
var patchWidget = /* @__PURE__ */ $lazy_patchWidget(286);
var haltText = function(v) {
  var parent2 = parentNode(v.node);
  return removeChild(v.node, parent2);
};
var $lazy_patchText = /* @__PURE__ */ $runtime_lazy4("patchText", "Halogen.VDom.DOM", function() {
  return function(state3, vdom) {
    if (vdom instanceof Grafted) {
      return $lazy_patchText(82)(state3, runGraft(vdom.value0));
    }
    ;
    if (vdom instanceof Text) {
      if (state3.value === vdom.value0) {
        return mkStep(new Step(state3.node, state3, $lazy_patchText(85), haltText));
      }
      ;
      if (otherwise) {
        var nextState = {
          build: state3.build,
          node: state3.node,
          value: vdom.value0
        };
        setTextContent(vdom.value0, state3.node);
        return mkStep(new Step(state3.node, nextState, $lazy_patchText(89), haltText));
      }
      ;
    }
    ;
    haltText(state3);
    return state3.build(vdom);
  };
});
var patchText = /* @__PURE__ */ $lazy_patchText(77);
var haltKeyed = function(v) {
  var parent2 = parentNode(v.node);
  removeChild(v.node, parent2);
  forInE(v.children, function(v1, s) {
    return halt(s);
  });
  return halt(v.attrs);
};
var haltElem = function(v) {
  var parent2 = parentNode(v.node);
  removeChild(v.node, parent2);
  forEachE(v.children, halt);
  return halt(v.attrs);
};
var eqElemSpec = function(ns1, v, ns2, v1) {
  var $63 = v === v1;
  if ($63) {
    if (ns1 instanceof Just && (ns2 instanceof Just && ns1.value0 === ns2.value0)) {
      return true;
    }
    ;
    if (ns1 instanceof Nothing && ns2 instanceof Nothing) {
      return true;
    }
    ;
    return false;
  }
  ;
  return false;
};
var $lazy_patchElem = /* @__PURE__ */ $runtime_lazy4("patchElem", "Halogen.VDom.DOM", function() {
  return function(state3, vdom) {
    if (vdom instanceof Grafted) {
      return $lazy_patchElem(135)(state3, runGraft(vdom.value0));
    }
    ;
    if (vdom instanceof Elem && eqElemSpec(state3.ns, state3.name, vdom.value0, vdom.value1)) {
      var v = length(vdom.value3);
      var v1 = length(state3.children);
      if (v1 === 0 && v === 0) {
        var attrs2 = step2(state3.attrs, vdom.value2);
        var nextState = {
          build: state3.build,
          node: state3.node,
          attrs: attrs2,
          ns: vdom.value0,
          name: vdom.value1,
          children: state3.children
        };
        return mkStep(new Step(state3.node, nextState, $lazy_patchElem(149), haltElem));
      }
      ;
      var onThis = function(v2, s) {
        return halt(s);
      };
      var onThese = function(ix, s, v2) {
        var res = step2(s, v2);
        insertChildIx(ix, extract2(res), state3.node);
        return res;
      };
      var onThat = function(ix, v2) {
        var res = state3.build(v2);
        insertChildIx(ix, extract2(res), state3.node);
        return res;
      };
      var children22 = diffWithIxE(state3.children, vdom.value3, onThese, onThis, onThat);
      var attrs2 = step2(state3.attrs, vdom.value2);
      var nextState = {
        build: state3.build,
        node: state3.node,
        attrs: attrs2,
        ns: vdom.value0,
        name: vdom.value1,
        children: children22
      };
      return mkStep(new Step(state3.node, nextState, $lazy_patchElem(172), haltElem));
    }
    ;
    haltElem(state3);
    return state3.build(vdom);
  };
});
var patchElem = /* @__PURE__ */ $lazy_patchElem(130);
var $lazy_patchKeyed = /* @__PURE__ */ $runtime_lazy4("patchKeyed", "Halogen.VDom.DOM", function() {
  return function(state3, vdom) {
    if (vdom instanceof Grafted) {
      return $lazy_patchKeyed(222)(state3, runGraft(vdom.value0));
    }
    ;
    if (vdom instanceof Keyed && eqElemSpec(state3.ns, state3.name, vdom.value0, vdom.value1)) {
      var v = length(vdom.value3);
      if (state3.length === 0 && v === 0) {
        var attrs2 = step2(state3.attrs, vdom.value2);
        var nextState = {
          build: state3.build,
          node: state3.node,
          attrs: attrs2,
          ns: vdom.value0,
          name: vdom.value1,
          children: state3.children,
          length: 0
        };
        return mkStep(new Step(state3.node, nextState, $lazy_patchKeyed(237), haltKeyed));
      }
      ;
      var onThis = function(v2, s) {
        return halt(s);
      };
      var onThese = function(v2, ix$prime, s, v3) {
        var res = step2(s, v3.value1);
        insertChildIx(ix$prime, extract2(res), state3.node);
        return res;
      };
      var onThat = function(v2, ix, v3) {
        var res = state3.build(v3.value1);
        insertChildIx(ix, extract2(res), state3.node);
        return res;
      };
      var children22 = diffWithKeyAndIxE(state3.children, vdom.value3, fst, onThese, onThis, onThat);
      var attrs2 = step2(state3.attrs, vdom.value2);
      var nextState = {
        build: state3.build,
        node: state3.node,
        attrs: attrs2,
        ns: vdom.value0,
        name: vdom.value1,
        children: children22,
        length: v
      };
      return mkStep(new Step(state3.node, nextState, $lazy_patchKeyed(261), haltKeyed));
    }
    ;
    haltKeyed(state3);
    return state3.build(vdom);
  };
});
var patchKeyed = /* @__PURE__ */ $lazy_patchKeyed(217);
var buildWidget = function(v, build, w) {
  var res = v.buildWidget(v)(w);
  var res$prime = unStep(function(v1) {
    return mkStep(new Step(v1.value0, {
      build,
      widget: res
    }, patchWidget, haltWidget));
  })(res);
  return res$prime;
};
var buildText = function(v, build, s) {
  var node = createTextNode(s, v.document);
  var state3 = {
    build,
    node,
    value: s
  };
  return mkStep(new Step(node, state3, patchText, haltText));
};
var buildKeyed = function(v, build, ns1, name1, as1, ch1) {
  var el = createElement(toNullable(ns1), name1, v.document);
  var node = toNode2(el);
  var onChild = function(v1, ix, v2) {
    var res = build(v2.value1);
    insertChildIx(ix, extract2(res), node);
    return res;
  };
  var children3 = strMapWithIxE(ch1, fst, onChild);
  var attrs = v.buildAttributes(el)(as1);
  var state3 = {
    build,
    node,
    attrs,
    ns: ns1,
    name: name1,
    children: children3,
    length: length(ch1)
  };
  return mkStep(new Step(node, state3, patchKeyed, haltKeyed));
};
var buildElem = function(v, build, ns1, name1, as1, ch1) {
  var el = createElement(toNullable(ns1), name1, v.document);
  var node = toNode2(el);
  var onChild = function(ix, child) {
    var res = build(child);
    insertChildIx(ix, extract2(res), node);
    return res;
  };
  var children3 = forE2(ch1, onChild);
  var attrs = v.buildAttributes(el)(as1);
  var state3 = {
    build,
    node,
    attrs,
    ns: ns1,
    name: name1,
    children: children3
  };
  return mkStep(new Step(node, state3, patchElem, haltElem));
};
var buildVDom = function(spec) {
  var $lazy_build = $runtime_lazy4("build", "Halogen.VDom.DOM", function() {
    return function(v) {
      if (v instanceof Text) {
        return buildText(spec, $lazy_build(59), v.value0);
      }
      ;
      if (v instanceof Elem) {
        return buildElem(spec, $lazy_build(60), v.value0, v.value1, v.value2, v.value3);
      }
      ;
      if (v instanceof Keyed) {
        return buildKeyed(spec, $lazy_build(61), v.value0, v.value1, v.value2, v.value3);
      }
      ;
      if (v instanceof Widget) {
        return buildWidget(spec, $lazy_build(62), v.value0);
      }
      ;
      if (v instanceof Grafted) {
        return $lazy_build(63)(runGraft(v.value0));
      }
      ;
      throw new Error("Failed pattern match at Halogen.VDom.DOM (line 58, column 27 - line 63, column 52): " + [v.constructor.name]);
    };
  });
  var build = $lazy_build(58);
  return build;
};

// output/Foreign/foreign.js
function typeOf(value12) {
  return typeof value12;
}

// output/Data.List/index.js
var reverse2 = /* @__PURE__ */ (function() {
  var go2 = function($copy_v) {
    return function($copy_v1) {
      var $tco_var_v = $copy_v;
      var $tco_done = false;
      var $tco_result;
      function $tco_loop(v, v1) {
        if (v1 instanceof Nil) {
          $tco_done = true;
          return v;
        }
        ;
        if (v1 instanceof Cons) {
          $tco_var_v = new Cons(v1.value0, v);
          $copy_v1 = v1.value1;
          return;
        }
        ;
        throw new Error("Failed pattern match at Data.List (line 368, column 3 - line 368, column 19): " + [v.constructor.name, v1.constructor.name]);
      }
      ;
      while (!$tco_done) {
        $tco_result = $tco_loop($tco_var_v, $copy_v1);
      }
      ;
      return $tco_result;
    };
  };
  return go2(Nil.value);
})();
var $$null2 = function(v) {
  if (v instanceof Nil) {
    return true;
  }
  ;
  return false;
};

// output/Data.List.NonEmpty/index.js
var singleton5 = /* @__PURE__ */ (function() {
  var $200 = singleton3(plusList);
  return function($201) {
    return NonEmptyList($200($201));
  };
})();
var cons2 = function(y4) {
  return function(v) {
    return new NonEmpty(y4, new Cons(v.value0, v.value1));
  };
};

// output/Foreign.Object/foreign.js
function _lookup(no, yes, k, m) {
  return k in m ? yes(m[k]) : no;
}
function toArrayWithKey(f) {
  return function(m) {
    var r = [];
    for (var k in m) {
      if (hasOwnProperty.call(m, k)) {
        r.push(f(k)(m[k]));
      }
    }
    return r;
  };
}
var keys = Object.keys || toArrayWithKey(function(k) {
  return function() {
    return k;
  };
});

// output/Foreign.Object/index.js
var lookup2 = /* @__PURE__ */ (function() {
  return runFn4(_lookup)(Nothing.value)(Just.create);
})();

// output/Halogen.VDom.DOM.Prop/index.js
var $runtime_lazy5 = function(name15, moduleName, init4) {
  var state3 = 0;
  var val;
  return function(lineNumber) {
    if (state3 === 2) return val;
    if (state3 === 1) throw new ReferenceError(name15 + " was needed before it finished initializing (module " + moduleName + ", line " + lineNumber + ")", moduleName, lineNumber);
    state3 = 1;
    val = init4();
    state3 = 2;
    return val;
  };
};
var Created = /* @__PURE__ */ (function() {
  function Created2(value0) {
    this.value0 = value0;
  }
  ;
  Created2.create = function(value0) {
    return new Created2(value0);
  };
  return Created2;
})();
var Removed = /* @__PURE__ */ (function() {
  function Removed2(value0) {
    this.value0 = value0;
  }
  ;
  Removed2.create = function(value0) {
    return new Removed2(value0);
  };
  return Removed2;
})();
var Attribute = /* @__PURE__ */ (function() {
  function Attribute2(value0, value1, value22) {
    this.value0 = value0;
    this.value1 = value1;
    this.value2 = value22;
  }
  ;
  Attribute2.create = function(value0) {
    return function(value1) {
      return function(value22) {
        return new Attribute2(value0, value1, value22);
      };
    };
  };
  return Attribute2;
})();
var Property = /* @__PURE__ */ (function() {
  function Property2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  Property2.create = function(value0) {
    return function(value1) {
      return new Property2(value0, value1);
    };
  };
  return Property2;
})();
var Handler = /* @__PURE__ */ (function() {
  function Handler2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  Handler2.create = function(value0) {
    return function(value1) {
      return new Handler2(value0, value1);
    };
  };
  return Handler2;
})();
var Ref = /* @__PURE__ */ (function() {
  function Ref2(value0) {
    this.value0 = value0;
  }
  ;
  Ref2.create = function(value0) {
    return new Ref2(value0);
  };
  return Ref2;
})();
var unsafeGetProperty = unsafeGetAny;
var setProperty = unsafeSetAny;
var removeProperty = function(key, el) {
  var v = hasAttribute(nullImpl, key, el);
  if (v) {
    return removeAttribute(nullImpl, key, el);
  }
  ;
  var v1 = typeOf(unsafeGetAny(key, el));
  if (v1 === "string") {
    return unsafeSetAny(key, "", el);
  }
  ;
  if (key === "rowSpan") {
    return unsafeSetAny(key, 1, el);
  }
  ;
  if (key === "colSpan") {
    return unsafeSetAny(key, 1, el);
  }
  ;
  return unsafeSetAny(key, jsUndefined, el);
};
var propToStrKey = function(v) {
  if (v instanceof Attribute && v.value0 instanceof Just) {
    return "attr/" + (v.value0.value0 + (":" + v.value1));
  }
  ;
  if (v instanceof Attribute) {
    return "attr/:" + v.value1;
  }
  ;
  if (v instanceof Property) {
    return "prop/" + v.value0;
  }
  ;
  if (v instanceof Handler) {
    return "handler/" + v.value0;
  }
  ;
  if (v instanceof Ref) {
    return "ref";
  }
  ;
  throw new Error("Failed pattern match at Halogen.VDom.DOM.Prop (line 182, column 16 - line 187, column 16): " + [v.constructor.name]);
};
var propFromString = unsafeCoerce2;
var propFromBoolean = unsafeCoerce2;
var buildProp = function(emit) {
  return function(el) {
    var removeProp = function(prevEvents) {
      return function(v, v1) {
        if (v1 instanceof Attribute) {
          return removeAttribute(toNullable(v1.value0), v1.value1, el);
        }
        ;
        if (v1 instanceof Property) {
          return removeProperty(v1.value0, el);
        }
        ;
        if (v1 instanceof Handler) {
          var handler3 = unsafeLookup(v1.value0, prevEvents);
          return removeEventListener2(v1.value0, fst(handler3), el);
        }
        ;
        if (v1 instanceof Ref) {
          return unit;
        }
        ;
        throw new Error("Failed pattern match at Halogen.VDom.DOM.Prop (line 169, column 5 - line 179, column 18): " + [v1.constructor.name]);
      };
    };
    var mbEmit = function(v) {
      if (v instanceof Just) {
        return emit(v.value0)();
      }
      ;
      return unit;
    };
    var haltProp = function(state3) {
      var v = lookup2("ref")(state3.props);
      if (v instanceof Just && v.value0 instanceof Ref) {
        return mbEmit(v.value0.value0(new Removed(el)));
      }
      ;
      return unit;
    };
    var diffProp = function(prevEvents, events) {
      return function(v, v1, v11, v2) {
        if (v11 instanceof Attribute && v2 instanceof Attribute) {
          var $66 = v11.value2 === v2.value2;
          if ($66) {
            return v2;
          }
          ;
          setAttribute(toNullable(v2.value0), v2.value1, v2.value2, el);
          return v2;
        }
        ;
        if (v11 instanceof Property && v2 instanceof Property) {
          var v4 = refEq2(v11.value1, v2.value1);
          if (v4) {
            return v2;
          }
          ;
          if (v2.value0 === "value") {
            var elVal = unsafeGetProperty("value", el);
            var $75 = refEq2(elVal, v2.value1);
            if ($75) {
              return v2;
            }
            ;
            setProperty(v2.value0, v2.value1, el);
            return v2;
          }
          ;
          setProperty(v2.value0, v2.value1, el);
          return v2;
        }
        ;
        if (v11 instanceof Handler && v2 instanceof Handler) {
          var handler3 = unsafeLookup(v2.value0, prevEvents);
          write(v2.value1)(snd(handler3))();
          pokeMutMap(v2.value0, handler3, events);
          return v2;
        }
        ;
        return v2;
      };
    };
    var applyProp = function(events) {
      return function(v, v1, v2) {
        if (v2 instanceof Attribute) {
          setAttribute(toNullable(v2.value0), v2.value1, v2.value2, el);
          return v2;
        }
        ;
        if (v2 instanceof Property) {
          setProperty(v2.value0, v2.value1, el);
          return v2;
        }
        ;
        if (v2 instanceof Handler) {
          var v3 = unsafeGetAny(v2.value0, events);
          if (unsafeHasAny(v2.value0, events)) {
            write(v2.value1)(snd(v3))();
            return v2;
          }
          ;
          var ref2 = $$new(v2.value1)();
          var listener = eventListener(function(ev) {
            return function __do2() {
              var f$prime = read(ref2)();
              return mbEmit(f$prime(ev));
            };
          })();
          pokeMutMap(v2.value0, new Tuple(listener, ref2), events);
          addEventListener2(v2.value0, listener, el);
          return v2;
        }
        ;
        if (v2 instanceof Ref) {
          mbEmit(v2.value0(new Created(el)));
          return v2;
        }
        ;
        throw new Error("Failed pattern match at Halogen.VDom.DOM.Prop (line 113, column 5 - line 135, column 15): " + [v2.constructor.name]);
      };
    };
    var $lazy_patchProp = $runtime_lazy5("patchProp", "Halogen.VDom.DOM.Prop", function() {
      return function(state3, ps2) {
        var events = newMutMap();
        var onThis = removeProp(state3.events);
        var onThese = diffProp(state3.events, events);
        var onThat = applyProp(events);
        var props = diffWithKeyAndIxE(state3.props, ps2, propToStrKey, onThese, onThis, onThat);
        var nextState = {
          events: unsafeFreeze2(events),
          props
        };
        return mkStep(new Step(unit, nextState, $lazy_patchProp(100), haltProp));
      };
    });
    var patchProp = $lazy_patchProp(87);
    var renderProp = function(ps1) {
      var events = newMutMap();
      var ps1$prime = strMapWithIxE(ps1, propToStrKey, applyProp(events));
      var state3 = {
        events: unsafeFreeze2(events),
        props: ps1$prime
      };
      return mkStep(new Step(unit, state3, patchProp, haltProp));
    };
    return renderProp;
  };
};

// output/Halogen.HTML.Core/index.js
var HTML = function(x4) {
  return x4;
};
var toPropValue = function(dict) {
  return dict.toPropValue;
};
var text5 = function($29) {
  return HTML(Text.create($29));
};
var prop = function(dictIsProp) {
  var toPropValue1 = toPropValue(dictIsProp);
  return function(v) {
    var $31 = Property.create(v);
    return function($32) {
      return $31(toPropValue1($32));
    };
  };
};
var isPropString = {
  toPropValue: propFromString
};
var isPropBoolean = {
  toPropValue: propFromBoolean
};
var handler = /* @__PURE__ */ (function() {
  return Handler.create;
})();
var element = function(ns) {
  return function(name15) {
    return function(props) {
      return function(children3) {
        return new Elem(ns, name15, props, children3);
      };
    };
  };
};
var attr = function(ns) {
  return function(v) {
    return Attribute.create(ns)(v);
  };
};

// output/Control.Applicative.Free/index.js
var identity7 = /* @__PURE__ */ identity(categoryFn);
var Pure = /* @__PURE__ */ (function() {
  function Pure2(value0) {
    this.value0 = value0;
  }
  ;
  Pure2.create = function(value0) {
    return new Pure2(value0);
  };
  return Pure2;
})();
var Lift = /* @__PURE__ */ (function() {
  function Lift3(value0) {
    this.value0 = value0;
  }
  ;
  Lift3.create = function(value0) {
    return new Lift3(value0);
  };
  return Lift3;
})();
var Ap = /* @__PURE__ */ (function() {
  function Ap2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  Ap2.create = function(value0) {
    return function(value1) {
      return new Ap2(value0, value1);
    };
  };
  return Ap2;
})();
var mkAp = function(fba) {
  return function(fb) {
    return new Ap(fba, fb);
  };
};
var liftFreeAp = /* @__PURE__ */ (function() {
  return Lift.create;
})();
var goLeft = function(dictApplicative) {
  var pure11 = pure(dictApplicative);
  return function(fStack) {
    return function(valStack) {
      return function(nat) {
        return function(func) {
          return function(count) {
            if (func instanceof Pure) {
              return new Tuple(new Cons({
                func: pure11(func.value0),
                count
              }, fStack), valStack);
            }
            ;
            if (func instanceof Lift) {
              return new Tuple(new Cons({
                func: nat(func.value0),
                count
              }, fStack), valStack);
            }
            ;
            if (func instanceof Ap) {
              return goLeft(dictApplicative)(fStack)(cons2(func.value1)(valStack))(nat)(func.value0)(count + 1 | 0);
            }
            ;
            throw new Error("Failed pattern match at Control.Applicative.Free (line 102, column 41 - line 105, column 81): " + [func.constructor.name]);
          };
        };
      };
    };
  };
};
var goApply = function(dictApplicative) {
  var apply2 = apply(dictApplicative.Apply0());
  return function(fStack) {
    return function(vals) {
      return function(gVal) {
        if (fStack instanceof Nil) {
          return new Left(gVal);
        }
        ;
        if (fStack instanceof Cons) {
          var gRes = apply2(fStack.value0.func)(gVal);
          var $31 = fStack.value0.count === 1;
          if ($31) {
            if (fStack.value1 instanceof Nil) {
              return new Left(gRes);
            }
            ;
            return goApply(dictApplicative)(fStack.value1)(vals)(gRes);
          }
          ;
          if (vals instanceof Nil) {
            return new Left(gRes);
          }
          ;
          if (vals instanceof Cons) {
            return new Right(new Tuple(new Cons({
              func: gRes,
              count: fStack.value0.count - 1 | 0
            }, fStack.value1), new NonEmpty(vals.value0, vals.value1)));
          }
          ;
          throw new Error("Failed pattern match at Control.Applicative.Free (line 83, column 11 - line 88, column 50): " + [vals.constructor.name]);
        }
        ;
        throw new Error("Failed pattern match at Control.Applicative.Free (line 72, column 3 - line 88, column 50): " + [fStack.constructor.name]);
      };
    };
  };
};
var functorFreeAp = {
  map: function(f) {
    return function(x4) {
      return mkAp(new Pure(f))(x4);
    };
  }
};
var foldFreeAp = function(dictApplicative) {
  var goApply1 = goApply(dictApplicative);
  var pure11 = pure(dictApplicative);
  var goLeft1 = goLeft(dictApplicative);
  return function(nat) {
    return function(z) {
      var go2 = function($copy_v) {
        var $tco_done = false;
        var $tco_result;
        function $tco_loop(v) {
          if (v.value1.value0 instanceof Pure) {
            var v1 = goApply1(v.value0)(v.value1.value1)(pure11(v.value1.value0.value0));
            if (v1 instanceof Left) {
              $tco_done = true;
              return v1.value0;
            }
            ;
            if (v1 instanceof Right) {
              $copy_v = v1.value0;
              return;
            }
            ;
            throw new Error("Failed pattern match at Control.Applicative.Free (line 54, column 17 - line 56, column 24): " + [v1.constructor.name]);
          }
          ;
          if (v.value1.value0 instanceof Lift) {
            var v1 = goApply1(v.value0)(v.value1.value1)(nat(v.value1.value0.value0));
            if (v1 instanceof Left) {
              $tco_done = true;
              return v1.value0;
            }
            ;
            if (v1 instanceof Right) {
              $copy_v = v1.value0;
              return;
            }
            ;
            throw new Error("Failed pattern match at Control.Applicative.Free (line 57, column 17 - line 59, column 24): " + [v1.constructor.name]);
          }
          ;
          if (v.value1.value0 instanceof Ap) {
            var nextVals = new NonEmpty(v.value1.value0.value1, v.value1.value1);
            $copy_v = goLeft1(v.value0)(nextVals)(nat)(v.value1.value0.value0)(1);
            return;
          }
          ;
          throw new Error("Failed pattern match at Control.Applicative.Free (line 53, column 5 - line 62, column 47): " + [v.value1.value0.constructor.name]);
        }
        ;
        while (!$tco_done) {
          $tco_result = $tco_loop($copy_v);
        }
        ;
        return $tco_result;
      };
      return go2(new Tuple(Nil.value, singleton5(z)));
    };
  };
};
var retractFreeAp = function(dictApplicative) {
  return foldFreeAp(dictApplicative)(identity7);
};
var applyFreeAp = {
  apply: function(fba) {
    return function(fb) {
      return mkAp(fba)(fb);
    };
  },
  Functor0: function() {
    return functorFreeAp;
  }
};
var applicativeFreeAp = /* @__PURE__ */ (function() {
  return {
    pure: Pure.create,
    Apply0: function() {
      return applyFreeAp;
    }
  };
})();
var foldFreeAp1 = /* @__PURE__ */ foldFreeAp(applicativeFreeAp);
var hoistFreeAp = function(f) {
  return foldFreeAp1(function($54) {
    return liftFreeAp(f($54));
  });
};

// output/Data.CatQueue/index.js
var CatQueue = /* @__PURE__ */ (function() {
  function CatQueue2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  CatQueue2.create = function(value0) {
    return function(value1) {
      return new CatQueue2(value0, value1);
    };
  };
  return CatQueue2;
})();
var uncons3 = function($copy_v) {
  var $tco_done = false;
  var $tco_result;
  function $tco_loop(v) {
    if (v.value0 instanceof Nil && v.value1 instanceof Nil) {
      $tco_done = true;
      return Nothing.value;
    }
    ;
    if (v.value0 instanceof Nil) {
      $copy_v = new CatQueue(reverse2(v.value1), Nil.value);
      return;
    }
    ;
    if (v.value0 instanceof Cons) {
      $tco_done = true;
      return new Just(new Tuple(v.value0.value0, new CatQueue(v.value0.value1, v.value1)));
    }
    ;
    throw new Error("Failed pattern match at Data.CatQueue (line 82, column 1 - line 82, column 63): " + [v.constructor.name]);
  }
  ;
  while (!$tco_done) {
    $tco_result = $tco_loop($copy_v);
  }
  ;
  return $tco_result;
};
var snoc3 = function(v) {
  return function(a2) {
    return new CatQueue(v.value0, new Cons(a2, v.value1));
  };
};
var $$null3 = function(v) {
  if (v.value0 instanceof Nil && v.value1 instanceof Nil) {
    return true;
  }
  ;
  return false;
};
var empty5 = /* @__PURE__ */ (function() {
  return new CatQueue(Nil.value, Nil.value);
})();

// output/Data.CatList/index.js
var CatNil = /* @__PURE__ */ (function() {
  function CatNil2() {
  }
  ;
  CatNil2.value = new CatNil2();
  return CatNil2;
})();
var CatCons = /* @__PURE__ */ (function() {
  function CatCons2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  CatCons2.create = function(value0) {
    return function(value1) {
      return new CatCons2(value0, value1);
    };
  };
  return CatCons2;
})();
var link = function(v) {
  return function(v1) {
    if (v instanceof CatNil) {
      return v1;
    }
    ;
    if (v1 instanceof CatNil) {
      return v;
    }
    ;
    if (v instanceof CatCons) {
      return new CatCons(v.value0, snoc3(v.value1)(v1));
    }
    ;
    throw new Error("Failed pattern match at Data.CatList (line 108, column 1 - line 108, column 54): " + [v.constructor.name, v1.constructor.name]);
  };
};
var foldr3 = function(k) {
  return function(b10) {
    return function(q2) {
      var foldl3 = function($copy_v) {
        return function($copy_v1) {
          return function($copy_v2) {
            var $tco_var_v = $copy_v;
            var $tco_var_v1 = $copy_v1;
            var $tco_done = false;
            var $tco_result;
            function $tco_loop(v, v1, v2) {
              if (v2 instanceof Nil) {
                $tco_done = true;
                return v1;
              }
              ;
              if (v2 instanceof Cons) {
                $tco_var_v = v;
                $tco_var_v1 = v(v1)(v2.value0);
                $copy_v2 = v2.value1;
                return;
              }
              ;
              throw new Error("Failed pattern match at Data.CatList (line 124, column 3 - line 124, column 59): " + [v.constructor.name, v1.constructor.name, v2.constructor.name]);
            }
            ;
            while (!$tco_done) {
              $tco_result = $tco_loop($tco_var_v, $tco_var_v1, $copy_v2);
            }
            ;
            return $tco_result;
          };
        };
      };
      var go2 = function($copy_xs) {
        return function($copy_ys) {
          var $tco_var_xs = $copy_xs;
          var $tco_done1 = false;
          var $tco_result;
          function $tco_loop(xs, ys) {
            var v = uncons3(xs);
            if (v instanceof Nothing) {
              $tco_done1 = true;
              return foldl3(function(x4) {
                return function(i2) {
                  return i2(x4);
                };
              })(b10)(ys);
            }
            ;
            if (v instanceof Just) {
              $tco_var_xs = v.value0.value1;
              $copy_ys = new Cons(k(v.value0.value0), ys);
              return;
            }
            ;
            throw new Error("Failed pattern match at Data.CatList (line 120, column 14 - line 122, column 67): " + [v.constructor.name]);
          }
          ;
          while (!$tco_done1) {
            $tco_result = $tco_loop($tco_var_xs, $copy_ys);
          }
          ;
          return $tco_result;
        };
      };
      return go2(q2)(Nil.value);
    };
  };
};
var uncons4 = function(v) {
  if (v instanceof CatNil) {
    return Nothing.value;
  }
  ;
  if (v instanceof CatCons) {
    return new Just(new Tuple(v.value0, (function() {
      var $66 = $$null3(v.value1);
      if ($66) {
        return CatNil.value;
      }
      ;
      return foldr3(link)(CatNil.value)(v.value1);
    })()));
  }
  ;
  throw new Error("Failed pattern match at Data.CatList (line 99, column 1 - line 99, column 61): " + [v.constructor.name]);
};
var empty6 = /* @__PURE__ */ (function() {
  return CatNil.value;
})();
var append3 = link;
var semigroupCatList = {
  append: append3
};
var snoc4 = function(cat) {
  return function(a2) {
    return append3(cat)(new CatCons(a2, empty5));
  };
};

// output/Control.Monad.Free/index.js
var $runtime_lazy6 = function(name15, moduleName, init4) {
  var state3 = 0;
  var val;
  return function(lineNumber) {
    if (state3 === 2) return val;
    if (state3 === 1) throw new ReferenceError(name15 + " was needed before it finished initializing (module " + moduleName + ", line " + lineNumber + ")", moduleName, lineNumber);
    state3 = 1;
    val = init4();
    state3 = 2;
    return val;
  };
};
var append4 = /* @__PURE__ */ append(semigroupCatList);
var Free = /* @__PURE__ */ (function() {
  function Free2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  Free2.create = function(value0) {
    return function(value1) {
      return new Free2(value0, value1);
    };
  };
  return Free2;
})();
var Return = /* @__PURE__ */ (function() {
  function Return2(value0) {
    this.value0 = value0;
  }
  ;
  Return2.create = function(value0) {
    return new Return2(value0);
  };
  return Return2;
})();
var Bind = /* @__PURE__ */ (function() {
  function Bind2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  Bind2.create = function(value0) {
    return function(value1) {
      return new Bind2(value0, value1);
    };
  };
  return Bind2;
})();
var toView = function($copy_v) {
  var $tco_done = false;
  var $tco_result;
  function $tco_loop(v) {
    var runExpF = function(v22) {
      return v22;
    };
    var concatF = function(v22) {
      return function(r) {
        return new Free(v22.value0, append4(v22.value1)(r));
      };
    };
    if (v.value0 instanceof Return) {
      var v2 = uncons4(v.value1);
      if (v2 instanceof Nothing) {
        $tco_done = true;
        return new Return(v.value0.value0);
      }
      ;
      if (v2 instanceof Just) {
        $copy_v = concatF(runExpF(v2.value0.value0)(v.value0.value0))(v2.value0.value1);
        return;
      }
      ;
      throw new Error("Failed pattern match at Control.Monad.Free (line 227, column 7 - line 231, column 64): " + [v2.constructor.name]);
    }
    ;
    if (v.value0 instanceof Bind) {
      $tco_done = true;
      return new Bind(v.value0.value0, function(a2) {
        return concatF(v.value0.value1(a2))(v.value1);
      });
    }
    ;
    throw new Error("Failed pattern match at Control.Monad.Free (line 225, column 3 - line 233, column 56): " + [v.value0.constructor.name]);
  }
  ;
  while (!$tco_done) {
    $tco_result = $tco_loop($copy_v);
  }
  ;
  return $tco_result;
};
var fromView = function(f) {
  return new Free(f, empty6);
};
var freeMonad = {
  Applicative0: function() {
    return freeApplicative;
  },
  Bind1: function() {
    return freeBind;
  }
};
var freeFunctor = {
  map: function(k) {
    return function(f) {
      return bindFlipped(freeBind)((function() {
        var $189 = pure(freeApplicative);
        return function($190) {
          return $189(k($190));
        };
      })())(f);
    };
  }
};
var freeBind = {
  bind: function(v) {
    return function(k) {
      return new Free(v.value0, snoc4(v.value1)(k));
    };
  },
  Apply0: function() {
    return $lazy_freeApply(0);
  }
};
var freeApplicative = {
  pure: function($191) {
    return fromView(Return.create($191));
  },
  Apply0: function() {
    return $lazy_freeApply(0);
  }
};
var $lazy_freeApply = /* @__PURE__ */ $runtime_lazy6("freeApply", "Control.Monad.Free", function() {
  return {
    apply: ap(freeMonad),
    Functor0: function() {
      return freeFunctor;
    }
  };
});
var pure4 = /* @__PURE__ */ pure(freeApplicative);
var liftF = function(f) {
  return fromView(new Bind(f, function($192) {
    return pure4($192);
  }));
};
var foldFree = function(dictMonadRec) {
  var Monad0 = dictMonadRec.Monad0();
  var map111 = map(Monad0.Bind1().Apply0().Functor0());
  var pure14 = pure(Monad0.Applicative0());
  var tailRecM4 = tailRecM(dictMonadRec);
  return function(k) {
    var go2 = function(f) {
      var v = toView(f);
      if (v instanceof Return) {
        return map111(Done.create)(pure14(v.value0));
      }
      ;
      if (v instanceof Bind) {
        return map111(function($199) {
          return Loop.create(v.value1($199));
        })(k(v.value0));
      }
      ;
      throw new Error("Failed pattern match at Control.Monad.Free (line 158, column 10 - line 160, column 37): " + [v.constructor.name]);
    };
    return tailRecM4(go2);
  };
};

// output/Halogen.Query.ChildQuery/index.js
var unChildQueryBox = unsafeCoerce2;

// output/Unsafe.Reference/foreign.js
function reallyUnsafeRefEq(a2) {
  return function(b10) {
    return a2 === b10;
  };
}

// output/Unsafe.Reference/index.js
var unsafeRefEq = reallyUnsafeRefEq;

// output/Halogen.Subscription/index.js
var $$void4 = /* @__PURE__ */ $$void(functorEffect);
var bind3 = /* @__PURE__ */ bind(bindEffect);
var append5 = /* @__PURE__ */ append(semigroupArray);
var traverse_2 = /* @__PURE__ */ traverse_(applicativeEffect);
var traverse_1 = /* @__PURE__ */ traverse_2(foldableArray);
var unsubscribe = function(v) {
  return v;
};
var subscribe = function(v) {
  return function(k) {
    return v(function($76) {
      return $$void4(k($76));
    });
  };
};
var notify = function(v) {
  return function(a2) {
    return v(a2);
  };
};
var create3 = function __do() {
  var subscribers = $$new([])();
  return {
    emitter: function(k) {
      return function __do2() {
        modify_2(function(v) {
          return append5(v)([k]);
        })(subscribers)();
        return modify_2(deleteBy(unsafeRefEq)(k))(subscribers);
      };
    },
    listener: function(a2) {
      return bind3(read(subscribers))(traverse_1(function(k) {
        return k(a2);
      }));
    }
  };
};

// output/Halogen.Query.HalogenM/index.js
var SubscriptionId = function(x4) {
  return x4;
};
var ForkId = function(x4) {
  return x4;
};
var State = /* @__PURE__ */ (function() {
  function State2(value0) {
    this.value0 = value0;
  }
  ;
  State2.create = function(value0) {
    return new State2(value0);
  };
  return State2;
})();
var Subscribe = /* @__PURE__ */ (function() {
  function Subscribe2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  Subscribe2.create = function(value0) {
    return function(value1) {
      return new Subscribe2(value0, value1);
    };
  };
  return Subscribe2;
})();
var Unsubscribe = /* @__PURE__ */ (function() {
  function Unsubscribe2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  Unsubscribe2.create = function(value0) {
    return function(value1) {
      return new Unsubscribe2(value0, value1);
    };
  };
  return Unsubscribe2;
})();
var Lift2 = /* @__PURE__ */ (function() {
  function Lift3(value0) {
    this.value0 = value0;
  }
  ;
  Lift3.create = function(value0) {
    return new Lift3(value0);
  };
  return Lift3;
})();
var ChildQuery2 = /* @__PURE__ */ (function() {
  function ChildQuery3(value0) {
    this.value0 = value0;
  }
  ;
  ChildQuery3.create = function(value0) {
    return new ChildQuery3(value0);
  };
  return ChildQuery3;
})();
var Raise = /* @__PURE__ */ (function() {
  function Raise2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  Raise2.create = function(value0) {
    return function(value1) {
      return new Raise2(value0, value1);
    };
  };
  return Raise2;
})();
var Par = /* @__PURE__ */ (function() {
  function Par2(value0) {
    this.value0 = value0;
  }
  ;
  Par2.create = function(value0) {
    return new Par2(value0);
  };
  return Par2;
})();
var Fork = /* @__PURE__ */ (function() {
  function Fork2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  Fork2.create = function(value0) {
    return function(value1) {
      return new Fork2(value0, value1);
    };
  };
  return Fork2;
})();
var Join = /* @__PURE__ */ (function() {
  function Join3(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  Join3.create = function(value0) {
    return function(value1) {
      return new Join3(value0, value1);
    };
  };
  return Join3;
})();
var Kill = /* @__PURE__ */ (function() {
  function Kill2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  Kill2.create = function(value0) {
    return function(value1) {
      return new Kill2(value0, value1);
    };
  };
  return Kill2;
})();
var GetRef = /* @__PURE__ */ (function() {
  function GetRef2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  GetRef2.create = function(value0) {
    return function(value1) {
      return new GetRef2(value0, value1);
    };
  };
  return GetRef2;
})();
var HalogenM = function(x4) {
  return x4;
};
var ordSubscriptionId = ordInt;
var ordForkId = ordInt;
var monadHalogenM = freeMonad;
var monadStateHalogenM = {
  state: function($181) {
    return HalogenM(liftF(State.create($181)));
  },
  Monad0: function() {
    return monadHalogenM;
  }
};
var monadEffectHalogenM = function(dictMonadEffect) {
  return {
    liftEffect: (function() {
      var $186 = liftEffect(dictMonadEffect);
      return function($187) {
        return HalogenM(liftF(Lift2.create($186($187))));
      };
    })(),
    Monad0: function() {
      return monadHalogenM;
    }
  };
};
var functorHalogenM = freeFunctor;
var bindHalogenM = freeBind;
var applicativeHalogenM = freeApplicative;

// output/Halogen.Query.HalogenQ/index.js
var Initialize = /* @__PURE__ */ (function() {
  function Initialize3(value0) {
    this.value0 = value0;
  }
  ;
  Initialize3.create = function(value0) {
    return new Initialize3(value0);
  };
  return Initialize3;
})();
var Finalize = /* @__PURE__ */ (function() {
  function Finalize2(value0) {
    this.value0 = value0;
  }
  ;
  Finalize2.create = function(value0) {
    return new Finalize2(value0);
  };
  return Finalize2;
})();
var Receive = /* @__PURE__ */ (function() {
  function Receive2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  Receive2.create = function(value0) {
    return function(value1) {
      return new Receive2(value0, value1);
    };
  };
  return Receive2;
})();
var Action2 = /* @__PURE__ */ (function() {
  function Action3(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  Action3.create = function(value0) {
    return function(value1) {
      return new Action3(value0, value1);
    };
  };
  return Action3;
})();
var Query = /* @__PURE__ */ (function() {
  function Query2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  Query2.create = function(value0) {
    return function(value1) {
      return new Query2(value0, value1);
    };
  };
  return Query2;
})();

// output/Halogen.VDom.Thunk/index.js
var $runtime_lazy7 = function(name15, moduleName, init4) {
  var state3 = 0;
  var val;
  return function(lineNumber) {
    if (state3 === 2) return val;
    if (state3 === 1) throw new ReferenceError(name15 + " was needed before it finished initializing (module " + moduleName + ", line " + lineNumber + ")", moduleName, lineNumber);
    state3 = 1;
    val = init4();
    state3 = 2;
    return val;
  };
};
var unsafeEqThunk = function(v, v1) {
  return refEq2(v.value0, v1.value0) && (refEq2(v.value1, v1.value1) && v.value1(v.value3, v1.value3));
};
var runThunk = function(v) {
  return v.value2(v.value3);
};
var buildThunk = function(toVDom) {
  var haltThunk = function(state3) {
    return halt(state3.vdom);
  };
  var $lazy_patchThunk = $runtime_lazy7("patchThunk", "Halogen.VDom.Thunk", function() {
    return function(state3, t2) {
      var $48 = unsafeEqThunk(state3.thunk, t2);
      if ($48) {
        return mkStep(new Step(extract2(state3.vdom), state3, $lazy_patchThunk(112), haltThunk));
      }
      ;
      var vdom = step2(state3.vdom, toVDom(runThunk(t2)));
      return mkStep(new Step(extract2(vdom), {
        vdom,
        thunk: t2
      }, $lazy_patchThunk(115), haltThunk));
    };
  });
  var patchThunk = $lazy_patchThunk(108);
  var renderThunk = function(spec) {
    return function(t) {
      var vdom = buildVDom(spec)(toVDom(runThunk(t)));
      return mkStep(new Step(extract2(vdom), {
        thunk: t,
        vdom
      }, patchThunk, haltThunk));
    };
  };
  return renderThunk;
};

// output/Halogen.Component/index.js
var voidLeft2 = /* @__PURE__ */ voidLeft(functorHalogenM);
var traverse_3 = /* @__PURE__ */ traverse_(applicativeHalogenM)(foldableMaybe);
var map10 = /* @__PURE__ */ map(functorHalogenM);
var pure5 = /* @__PURE__ */ pure(applicativeHalogenM);
var ComponentSlot = /* @__PURE__ */ (function() {
  function ComponentSlot2(value0) {
    this.value0 = value0;
  }
  ;
  ComponentSlot2.create = function(value0) {
    return new ComponentSlot2(value0);
  };
  return ComponentSlot2;
})();
var ThunkSlot = /* @__PURE__ */ (function() {
  function ThunkSlot2(value0) {
    this.value0 = value0;
  }
  ;
  ThunkSlot2.create = function(value0) {
    return new ThunkSlot2(value0);
  };
  return ThunkSlot2;
})();
var unComponentSlot = unsafeCoerce2;
var unComponent = unsafeCoerce2;
var mkEval = function(args) {
  return function(v) {
    if (v instanceof Initialize) {
      return voidLeft2(traverse_3(args.handleAction)(args.initialize))(v.value0);
    }
    ;
    if (v instanceof Finalize) {
      return voidLeft2(traverse_3(args.handleAction)(args.finalize))(v.value0);
    }
    ;
    if (v instanceof Receive) {
      return voidLeft2(traverse_3(args.handleAction)(args.receive(v.value0)))(v.value1);
    }
    ;
    if (v instanceof Action2) {
      return voidLeft2(args.handleAction(v.value0))(v.value1);
    }
    ;
    if (v instanceof Query) {
      return unCoyoneda(function(g) {
        var $45 = map10(maybe(v.value1(unit))(g));
        return function($46) {
          return $45(args.handleQuery($46));
        };
      })(v.value0);
    }
    ;
    throw new Error("Failed pattern match at Halogen.Component (line 182, column 15 - line 192, column 71): " + [v.constructor.name]);
  };
};
var mkComponent = unsafeCoerce2;
var defaultEval = /* @__PURE__ */ (function() {
  return {
    handleAction: $$const(pure5(unit)),
    handleQuery: $$const(pure5(Nothing.value)),
    receive: $$const(Nothing.value),
    initialize: Nothing.value,
    finalize: Nothing.value
  };
})();

// output/Halogen.HTML.Elements/index.js
var element2 = /* @__PURE__ */ (function() {
  return element(Nothing.value);
})();
var h1 = /* @__PURE__ */ element2("h1");
var p = /* @__PURE__ */ element2("p");
var span3 = /* @__PURE__ */ element2("span");
var div2 = /* @__PURE__ */ element2("div");
var button = /* @__PURE__ */ element2("button");

// output/Web.UIEvent.MouseEvent.EventTypes/index.js
var click2 = "click";

// output/Halogen.HTML.Events/index.js
var mouseHandler = unsafeCoerce2;
var handler2 = function(et) {
  return function(f) {
    return handler(et)(function(ev) {
      return new Just(new Action(f(ev)));
    });
  };
};
var onClick = /* @__PURE__ */ (function() {
  var $15 = handler2(click2);
  return function($16) {
    return $15(mouseHandler($16));
  };
})();

// output/Halogen.HTML.Properties/index.js
var prop2 = function(dictIsProp) {
  return prop(dictIsProp);
};
var prop1 = /* @__PURE__ */ prop2(isPropBoolean);
var prop22 = /* @__PURE__ */ prop2(isPropString);
var id2 = /* @__PURE__ */ prop22("id");
var disabled10 = /* @__PURE__ */ prop1("disabled");
var attr2 = /* @__PURE__ */ (function() {
  return attr(Nothing.value);
})();
var style = /* @__PURE__ */ attr2("style");

// output/Control.Monad.Fork.Class/index.js
var monadForkAff = {
  suspend: suspendAff,
  fork: forkAff,
  join: joinFiber,
  Monad0: function() {
    return monadAff;
  },
  Functor1: function() {
    return functorFiber;
  }
};
var fork = function(dict) {
  return dict.fork;
};

// output/Halogen.Aff.Driver.State/index.js
var unRenderStateX = unsafeCoerce2;
var unDriverStateX = unsafeCoerce2;
var renderStateX_ = function(dictApplicative) {
  var traverse_8 = traverse_(dictApplicative)(foldableMaybe);
  return function(f) {
    return unDriverStateX(function(st) {
      return traverse_8(f)(st.rendering);
    });
  };
};
var mkRenderStateX = unsafeCoerce2;
var renderStateX = function(dictFunctor) {
  return function(f) {
    return unDriverStateX(function(st) {
      return mkRenderStateX(f(st.rendering));
    });
  };
};
var mkDriverStateXRef = unsafeCoerce2;
var mapDriverState = function(f) {
  return function(v) {
    return f(v);
  };
};
var initDriverState = function(component2) {
  return function(input3) {
    return function(handler3) {
      return function(lchs) {
        return function __do2() {
          var selfRef = $$new({})();
          var childrenIn = $$new(empty3)();
          var childrenOut = $$new(empty3)();
          var handlerRef = $$new(handler3)();
          var pendingQueries = $$new(new Just(Nil.value))();
          var pendingOuts = $$new(new Just(Nil.value))();
          var pendingHandlers = $$new(Nothing.value)();
          var fresh2 = $$new(1)();
          var subscriptions = $$new(new Just(empty2))();
          var forks = $$new(empty2)();
          var ds = {
            component: component2,
            state: component2.initialState(input3),
            refs: empty2,
            children: empty3,
            childrenIn,
            childrenOut,
            selfRef,
            handlerRef,
            pendingQueries,
            pendingOuts,
            pendingHandlers,
            rendering: Nothing.value,
            fresh: fresh2,
            subscriptions,
            forks,
            lifecycleHandlers: lchs
          };
          write(ds)(selfRef)();
          return mkDriverStateXRef(selfRef);
        };
      };
    };
  };
};

// output/Halogen.Aff.Driver.Eval/index.js
var traverse_4 = /* @__PURE__ */ traverse_(applicativeEffect)(foldableMaybe);
var bindFlipped5 = /* @__PURE__ */ bindFlipped(bindMaybe);
var lookup4 = /* @__PURE__ */ lookup(ordSubscriptionId);
var bind12 = /* @__PURE__ */ bind(bindAff);
var liftEffect4 = /* @__PURE__ */ liftEffect(monadEffectAff);
var discard3 = /* @__PURE__ */ discard(discardUnit);
var discard1 = /* @__PURE__ */ discard3(bindAff);
var traverse_12 = /* @__PURE__ */ traverse_(applicativeAff);
var traverse_22 = /* @__PURE__ */ traverse_12(foldableList);
var fork3 = /* @__PURE__ */ fork(monadForkAff);
var parSequence_2 = /* @__PURE__ */ parSequence_(parallelAff)(applicativeParAff)(foldableList);
var pure6 = /* @__PURE__ */ pure(applicativeAff);
var map13 = /* @__PURE__ */ map(functorCoyoneda);
var parallel3 = /* @__PURE__ */ parallel(parallelAff);
var map14 = /* @__PURE__ */ map(functorAff);
var sequential2 = /* @__PURE__ */ sequential(parallelAff);
var map22 = /* @__PURE__ */ map(functorMaybe);
var insert3 = /* @__PURE__ */ insert(ordSubscriptionId);
var retractFreeAp2 = /* @__PURE__ */ retractFreeAp(applicativeParAff);
var $$delete2 = /* @__PURE__ */ $$delete(ordForkId);
var unlessM2 = /* @__PURE__ */ unlessM(monadEffect);
var insert1 = /* @__PURE__ */ insert(ordForkId);
var traverse_32 = /* @__PURE__ */ traverse_12(foldableMaybe);
var lookup1 = /* @__PURE__ */ lookup(ordForkId);
var lookup22 = /* @__PURE__ */ lookup(ordString);
var foldFree2 = /* @__PURE__ */ foldFree(monadRecAff);
var alter2 = /* @__PURE__ */ alter(ordString);
var unsubscribe3 = function(sid) {
  return function(ref2) {
    return function __do2() {
      var v = read(ref2)();
      var subs = read(v.subscriptions)();
      return traverse_4(unsubscribe)(bindFlipped5(lookup4(sid))(subs))();
    };
  };
};
var queueOrRun = function(ref2) {
  return function(au) {
    return bind12(liftEffect4(read(ref2)))(function(v) {
      if (v instanceof Nothing) {
        return au;
      }
      ;
      if (v instanceof Just) {
        return liftEffect4(write(new Just(new Cons(au, v.value0)))(ref2));
      }
      ;
      throw new Error("Failed pattern match at Halogen.Aff.Driver.Eval (line 188, column 33 - line 190, column 57): " + [v.constructor.name]);
    });
  };
};
var handleLifecycle = function(lchs) {
  return function(f) {
    return discard1(liftEffect4(write({
      initializers: Nil.value,
      finalizers: Nil.value
    })(lchs)))(function() {
      return bind12(liftEffect4(f))(function(result) {
        return bind12(liftEffect4(read(lchs)))(function(v) {
          return discard1(traverse_22(fork3)(v.finalizers))(function() {
            return discard1(parSequence_2(v.initializers))(function() {
              return pure6(result);
            });
          });
        });
      });
    });
  };
};
var handleAff = /* @__PURE__ */ runAff_(/* @__PURE__ */ either(throwException)(/* @__PURE__ */ $$const(/* @__PURE__ */ pure(applicativeEffect)(unit))));
var fresh = function(f) {
  return function(ref2) {
    return bind12(liftEffect4(read(ref2)))(function(v) {
      return liftEffect4(modify$prime(function(i2) {
        return {
          state: i2 + 1 | 0,
          value: f(i2)
        };
      })(v.fresh));
    });
  };
};
var evalQ = function(render2) {
  return function(ref2) {
    return function(q2) {
      return bind12(liftEffect4(read(ref2)))(function(v) {
        return evalM(render2)(ref2)(v["component"]["eval"](new Query(map13(Just.create)(liftCoyoneda(q2)), $$const(Nothing.value))));
      });
    };
  };
};
var evalM = function(render2) {
  return function(initRef) {
    return function(v) {
      var evalChildQuery = function(ref2) {
        return function(cqb) {
          return bind12(liftEffect4(read(ref2)))(function(v1) {
            return unChildQueryBox(function(v2) {
              var evalChild = function(v3) {
                return parallel3(bind12(liftEffect4(read(v3)))(function(dsx) {
                  return unDriverStateX(function(ds) {
                    return evalQ(render2)(ds.selfRef)(v2.value1);
                  })(dsx);
                }));
              };
              return map14(v2.value2)(sequential2(v2.value0(applicativeParAff)(evalChild)(v1.children)));
            })(cqb);
          });
        };
      };
      var go2 = function(ref2) {
        return function(v1) {
          if (v1 instanceof State) {
            return bind12(liftEffect4(read(ref2)))(function(v2) {
              var v3 = v1.value0(v2.state);
              if (unsafeRefEq(v2.state)(v3.value1)) {
                return pure6(v3.value0);
              }
              ;
              if (otherwise) {
                return discard1(liftEffect4(write({
                  component: v2.component,
                  refs: v2.refs,
                  children: v2.children,
                  childrenIn: v2.childrenIn,
                  childrenOut: v2.childrenOut,
                  selfRef: v2.selfRef,
                  handlerRef: v2.handlerRef,
                  pendingQueries: v2.pendingQueries,
                  pendingOuts: v2.pendingOuts,
                  pendingHandlers: v2.pendingHandlers,
                  rendering: v2.rendering,
                  fresh: v2.fresh,
                  subscriptions: v2.subscriptions,
                  forks: v2.forks,
                  lifecycleHandlers: v2.lifecycleHandlers,
                  state: v3.value1
                })(ref2)))(function() {
                  return discard1(handleLifecycle(v2.lifecycleHandlers)(render2(v2.lifecycleHandlers)(ref2)))(function() {
                    return pure6(v3.value0);
                  });
                });
              }
              ;
              throw new Error("Failed pattern match at Halogen.Aff.Driver.Eval (line 86, column 7 - line 92, column 21): " + [v3.constructor.name]);
            });
          }
          ;
          if (v1 instanceof Subscribe) {
            return bind12(fresh(SubscriptionId)(ref2))(function(sid) {
              return bind12(liftEffect4(subscribe(v1.value0(sid))(function(act) {
                return handleAff(evalF(render2)(ref2)(new Action(act)));
              })))(function(finalize) {
                return bind12(liftEffect4(read(ref2)))(function(v2) {
                  return discard1(liftEffect4(modify_2(map22(insert3(sid)(finalize)))(v2.subscriptions)))(function() {
                    return pure6(v1.value1(sid));
                  });
                });
              });
            });
          }
          ;
          if (v1 instanceof Unsubscribe) {
            return discard1(liftEffect4(unsubscribe3(v1.value0)(ref2)))(function() {
              return pure6(v1.value1);
            });
          }
          ;
          if (v1 instanceof Lift2) {
            return v1.value0;
          }
          ;
          if (v1 instanceof ChildQuery2) {
            return evalChildQuery(ref2)(v1.value0);
          }
          ;
          if (v1 instanceof Raise) {
            return bind12(liftEffect4(read(ref2)))(function(v2) {
              return bind12(liftEffect4(read(v2.handlerRef)))(function(handler3) {
                return discard1(queueOrRun(v2.pendingOuts)(handler3(v1.value0)))(function() {
                  return pure6(v1.value1);
                });
              });
            });
          }
          ;
          if (v1 instanceof Par) {
            return sequential2(retractFreeAp2(hoistFreeAp((function() {
              var $119 = evalM(render2)(ref2);
              return function($120) {
                return parallel3($119($120));
              };
            })())(v1.value0)));
          }
          ;
          if (v1 instanceof Fork) {
            return bind12(fresh(ForkId)(ref2))(function(fid) {
              return bind12(liftEffect4(read(ref2)))(function(v2) {
                return bind12(liftEffect4($$new(false)))(function(doneRef) {
                  return bind12(fork3($$finally(liftEffect4(function __do2() {
                    modify_2($$delete2(fid))(v2.forks)();
                    return write(true)(doneRef)();
                  }))(evalM(render2)(ref2)(v1.value0))))(function(fiber) {
                    return discard1(liftEffect4(unlessM2(read(doneRef))(modify_2(insert1(fid)(fiber))(v2.forks))))(function() {
                      return pure6(v1.value1(fid));
                    });
                  });
                });
              });
            });
          }
          ;
          if (v1 instanceof Join) {
            return bind12(liftEffect4(read(ref2)))(function(v2) {
              return bind12(liftEffect4(read(v2.forks)))(function(forkMap) {
                return discard1(traverse_32(joinFiber)(lookup1(v1.value0)(forkMap)))(function() {
                  return pure6(v1.value1);
                });
              });
            });
          }
          ;
          if (v1 instanceof Kill) {
            return bind12(liftEffect4(read(ref2)))(function(v2) {
              return bind12(liftEffect4(read(v2.forks)))(function(forkMap) {
                return discard1(traverse_32(killFiber(error("Cancelled")))(lookup1(v1.value0)(forkMap)))(function() {
                  return pure6(v1.value1);
                });
              });
            });
          }
          ;
          if (v1 instanceof GetRef) {
            return bind12(liftEffect4(read(ref2)))(function(v2) {
              return pure6(v1.value1(lookup22(v1.value0)(v2.refs)));
            });
          }
          ;
          throw new Error("Failed pattern match at Halogen.Aff.Driver.Eval (line 83, column 12 - line 139, column 33): " + [v1.constructor.name]);
        };
      };
      return foldFree2(go2(initRef))(v);
    };
  };
};
var evalF = function(render2) {
  return function(ref2) {
    return function(v) {
      if (v instanceof RefUpdate) {
        return liftEffect4(flip(modify_2)(ref2)(mapDriverState(function(st) {
          return {
            component: st.component,
            state: st.state,
            children: st.children,
            childrenIn: st.childrenIn,
            childrenOut: st.childrenOut,
            selfRef: st.selfRef,
            handlerRef: st.handlerRef,
            pendingQueries: st.pendingQueries,
            pendingOuts: st.pendingOuts,
            pendingHandlers: st.pendingHandlers,
            rendering: st.rendering,
            fresh: st.fresh,
            subscriptions: st.subscriptions,
            forks: st.forks,
            lifecycleHandlers: st.lifecycleHandlers,
            refs: alter2($$const(v.value1))(v.value0)(st.refs)
          };
        })));
      }
      ;
      if (v instanceof Action) {
        return bind12(liftEffect4(read(ref2)))(function(v1) {
          return evalM(render2)(ref2)(v1["component"]["eval"](new Action2(v.value0, unit)));
        });
      }
      ;
      throw new Error("Failed pattern match at Halogen.Aff.Driver.Eval (line 52, column 20 - line 58, column 62): " + [v.constructor.name]);
    };
  };
};

// output/Halogen.Aff.Driver/index.js
var bind4 = /* @__PURE__ */ bind(bindEffect);
var discard4 = /* @__PURE__ */ discard(discardUnit);
var for_2 = /* @__PURE__ */ for_(applicativeEffect)(foldableMaybe);
var traverse_5 = /* @__PURE__ */ traverse_(applicativeAff)(foldableList);
var fork4 = /* @__PURE__ */ fork(monadForkAff);
var bindFlipped6 = /* @__PURE__ */ bindFlipped(bindEffect);
var traverse_13 = /* @__PURE__ */ traverse_(applicativeEffect);
var traverse_23 = /* @__PURE__ */ traverse_13(foldableMaybe);
var traverse_33 = /* @__PURE__ */ traverse_13(foldableMap);
var discard22 = /* @__PURE__ */ discard4(bindAff);
var parSequence_3 = /* @__PURE__ */ parSequence_(parallelAff)(applicativeParAff)(foldableList);
var liftEffect5 = /* @__PURE__ */ liftEffect(monadEffectAff);
var pure7 = /* @__PURE__ */ pure(applicativeEffect);
var map15 = /* @__PURE__ */ map(functorEffect);
var pure12 = /* @__PURE__ */ pure(applicativeAff);
var when2 = /* @__PURE__ */ when(applicativeEffect);
var renderStateX2 = /* @__PURE__ */ renderStateX(functorEffect);
var $$void5 = /* @__PURE__ */ $$void(functorAff);
var foreachSlot2 = /* @__PURE__ */ foreachSlot(applicativeEffect);
var renderStateX_2 = /* @__PURE__ */ renderStateX_(applicativeEffect);
var tailRecM3 = /* @__PURE__ */ tailRecM(monadRecEffect);
var voidLeft3 = /* @__PURE__ */ voidLeft(functorEffect);
var bind13 = /* @__PURE__ */ bind(bindAff);
var liftEffect1 = /* @__PURE__ */ liftEffect(monadEffectEffect);
var newLifecycleHandlers = /* @__PURE__ */ (function() {
  return $$new({
    initializers: Nil.value,
    finalizers: Nil.value
  });
})();
var handlePending = function(ref2) {
  return function __do2() {
    var queue = read(ref2)();
    write(Nothing.value)(ref2)();
    return for_2(queue)((function() {
      var $59 = traverse_5(fork4);
      return function($60) {
        return handleAff($59(reverse2($60)));
      };
    })())();
  };
};
var cleanupSubscriptionsAndForks = function(v) {
  return function __do2() {
    bindFlipped6(traverse_23(traverse_33(unsubscribe)))(read(v.subscriptions))();
    write(Nothing.value)(v.subscriptions)();
    bindFlipped6(traverse_33((function() {
      var $61 = killFiber(error("finalized"));
      return function($62) {
        return handleAff($61($62));
      };
    })()))(read(v.forks))();
    return write(empty2)(v.forks)();
  };
};
var runUI = function(renderSpec2) {
  return function(component2) {
    return function(i2) {
      var squashChildInitializers = function(lchs) {
        return function(preInits) {
          return unDriverStateX(function(st) {
            var parentInitializer = evalM(render2)(st.selfRef)(st["component"]["eval"](new Initialize(unit)));
            return modify_2(function(handlers) {
              return {
                initializers: new Cons(discard22(parSequence_3(reverse2(handlers.initializers)))(function() {
                  return discard22(parentInitializer)(function() {
                    return liftEffect5(function __do2() {
                      handlePending(st.pendingQueries)();
                      return handlePending(st.pendingOuts)();
                    });
                  });
                }), preInits),
                finalizers: handlers.finalizers
              };
            })(lchs);
          });
        };
      };
      var runComponent = function(lchs) {
        return function(handler3) {
          return function(j) {
            return unComponent(function(c) {
              return function __do2() {
                var lchs$prime = newLifecycleHandlers();
                var $$var2 = initDriverState(c)(j)(handler3)(lchs$prime)();
                var pre2 = read(lchs)();
                write({
                  initializers: Nil.value,
                  finalizers: pre2.finalizers
                })(lchs)();
                bindFlipped6(unDriverStateX((function() {
                  var $63 = render2(lchs);
                  return function($64) {
                    return $63((function(v) {
                      return v.selfRef;
                    })($64));
                  };
                })()))(read($$var2))();
                bindFlipped6(squashChildInitializers(lchs)(pre2.initializers))(read($$var2))();
                return $$var2;
              };
            });
          };
        };
      };
      var renderChild = function(lchs) {
        return function(handler3) {
          return function(childrenInRef) {
            return function(childrenOutRef) {
              return unComponentSlot(function(slot) {
                return function __do2() {
                  var childrenIn = map15(slot.pop)(read(childrenInRef))();
                  var $$var2 = (function() {
                    if (childrenIn instanceof Just) {
                      write(childrenIn.value0.value1)(childrenInRef)();
                      var dsx = read(childrenIn.value0.value0)();
                      unDriverStateX(function(st) {
                        return function __do3() {
                          flip(write)(st.handlerRef)((function() {
                            var $65 = maybe(pure12(unit))(handler3);
                            return function($66) {
                              return $65(slot.output($66));
                            };
                          })())();
                          return handleAff(evalM(render2)(st.selfRef)(st["component"]["eval"](new Receive(slot.input, unit))))();
                        };
                      })(dsx)();
                      return childrenIn.value0.value0;
                    }
                    ;
                    if (childrenIn instanceof Nothing) {
                      return runComponent(lchs)((function() {
                        var $67 = maybe(pure12(unit))(handler3);
                        return function($68) {
                          return $67(slot.output($68));
                        };
                      })())(slot.input)(slot.component)();
                    }
                    ;
                    throw new Error("Failed pattern match at Halogen.Aff.Driver (line 213, column 14 - line 222, column 98): " + [childrenIn.constructor.name]);
                  })();
                  var isDuplicate = map15(function($69) {
                    return isJust(slot.get($69));
                  })(read(childrenOutRef))();
                  when2(isDuplicate)(warn("Halogen: Duplicate slot address was detected during rendering, unexpected results may occur"))();
                  modify_2(slot.set($$var2))(childrenOutRef)();
                  return bind4(read($$var2))(renderStateX2(function(v) {
                    if (v instanceof Nothing) {
                      return $$throw("Halogen internal error: child was not initialized in renderChild");
                    }
                    ;
                    if (v instanceof Just) {
                      return pure7(renderSpec2.renderChild(v.value0));
                    }
                    ;
                    throw new Error("Failed pattern match at Halogen.Aff.Driver (line 227, column 37 - line 229, column 50): " + [v.constructor.name]);
                  }))();
                };
              });
            };
          };
        };
      };
      var render2 = function(lchs) {
        return function($$var2) {
          return function __do2() {
            var v = read($$var2)();
            var shouldProcessHandlers = map15(isNothing)(read(v.pendingHandlers))();
            when2(shouldProcessHandlers)(write(new Just(Nil.value))(v.pendingHandlers))();
            write(empty3)(v.childrenOut)();
            write(v.children)(v.childrenIn)();
            var handler3 = (function() {
              var $70 = queueOrRun(v.pendingHandlers);
              var $71 = evalF(render2)(v.selfRef);
              return function($72) {
                return $70($$void5($71($72)));
              };
            })();
            var childHandler = (function() {
              var $73 = queueOrRun(v.pendingQueries);
              return function($74) {
                return $73(handler3(Action.create($74)));
              };
            })();
            var rendering = renderSpec2.render(function($75) {
              return handleAff(handler3($75));
            })(renderChild(lchs)(childHandler)(v.childrenIn)(v.childrenOut))(v.component.render(v.state))(v.rendering)();
            var children3 = read(v.childrenOut)();
            var childrenIn = read(v.childrenIn)();
            foreachSlot2(childrenIn)(function(v1) {
              return function __do3() {
                var childDS = read(v1)();
                renderStateX_2(renderSpec2.removeChild)(childDS)();
                return finalize(lchs)(childDS)();
              };
            })();
            flip(modify_2)(v.selfRef)(mapDriverState(function(ds$prime) {
              return {
                component: ds$prime.component,
                state: ds$prime.state,
                refs: ds$prime.refs,
                childrenIn: ds$prime.childrenIn,
                childrenOut: ds$prime.childrenOut,
                selfRef: ds$prime.selfRef,
                handlerRef: ds$prime.handlerRef,
                pendingQueries: ds$prime.pendingQueries,
                pendingOuts: ds$prime.pendingOuts,
                pendingHandlers: ds$prime.pendingHandlers,
                fresh: ds$prime.fresh,
                subscriptions: ds$prime.subscriptions,
                forks: ds$prime.forks,
                lifecycleHandlers: ds$prime.lifecycleHandlers,
                rendering: new Just(rendering),
                children: children3
              };
            }))();
            return when2(shouldProcessHandlers)(flip(tailRecM3)(unit)(function(v1) {
              return function __do3() {
                var handlers = read(v.pendingHandlers)();
                write(new Just(Nil.value))(v.pendingHandlers)();
                traverse_23((function() {
                  var $76 = traverse_5(fork4);
                  return function($77) {
                    return handleAff($76(reverse2($77)));
                  };
                })())(handlers)();
                var mmore = read(v.pendingHandlers)();
                var $52 = maybe(false)($$null2)(mmore);
                if ($52) {
                  return voidLeft3(write(Nothing.value)(v.pendingHandlers))(new Done(unit))();
                }
                ;
                return new Loop(unit);
              };
            }))();
          };
        };
      };
      var finalize = function(lchs) {
        return unDriverStateX(function(st) {
          return function __do2() {
            cleanupSubscriptionsAndForks(st)();
            var f = evalM(render2)(st.selfRef)(st["component"]["eval"](new Finalize(unit)));
            modify_2(function(handlers) {
              return {
                initializers: handlers.initializers,
                finalizers: new Cons(f, handlers.finalizers)
              };
            })(lchs)();
            return foreachSlot2(st.children)(function(v) {
              return function __do3() {
                var dsx = read(v)();
                return finalize(lchs)(dsx)();
              };
            })();
          };
        });
      };
      var evalDriver = function(disposed) {
        return function(ref2) {
          return function(q2) {
            return bind13(liftEffect5(read(disposed)))(function(v) {
              if (v) {
                return pure12(Nothing.value);
              }
              ;
              return evalQ(render2)(ref2)(q2);
            });
          };
        };
      };
      var dispose = function(disposed) {
        return function(lchs) {
          return function(dsx) {
            return handleLifecycle(lchs)(function __do2() {
              var v = read(disposed)();
              if (v) {
                return unit;
              }
              ;
              write(true)(disposed)();
              finalize(lchs)(dsx)();
              return unDriverStateX(function(v1) {
                return function __do3() {
                  var v2 = liftEffect1(read(v1.selfRef))();
                  return for_2(v2.rendering)(renderSpec2.dispose)();
                };
              })(dsx)();
            });
          };
        };
      };
      return bind13(liftEffect5(newLifecycleHandlers))(function(lchs) {
        return bind13(liftEffect5($$new(false)))(function(disposed) {
          return handleLifecycle(lchs)(function __do2() {
            var sio = create3();
            var dsx = bindFlipped6(read)(runComponent(lchs)((function() {
              var $78 = notify(sio.listener);
              return function($79) {
                return liftEffect5($78($79));
              };
            })())(i2)(component2))();
            return unDriverStateX(function(st) {
              return pure7({
                query: evalDriver(disposed)(st.selfRef),
                messages: sio.emitter,
                dispose: dispose(disposed)(lchs)(dsx)
              });
            })(dsx)();
          });
        });
      });
    };
  };
};

// output/Web.DOM.Node/foreign.js
var getEffProp2 = function(name15) {
  return function(node) {
    return function() {
      return node[name15];
    };
  };
};
var baseURI = getEffProp2("baseURI");
var _ownerDocument = getEffProp2("ownerDocument");
var _parentNode = getEffProp2("parentNode");
var _parentElement = getEffProp2("parentElement");
var childNodes = getEffProp2("childNodes");
var _firstChild = getEffProp2("firstChild");
var _lastChild = getEffProp2("lastChild");
var _previousSibling = getEffProp2("previousSibling");
var _nextSibling = getEffProp2("nextSibling");
var _nodeValue = getEffProp2("nodeValue");
var textContent = getEffProp2("textContent");
function insertBefore(node1) {
  return function(node2) {
    return function(parent2) {
      return function() {
        parent2.insertBefore(node1, node2);
      };
    };
  };
}
function appendChild(node) {
  return function(parent2) {
    return function() {
      parent2.appendChild(node);
    };
  };
}
function removeChild2(node) {
  return function(parent2) {
    return function() {
      parent2.removeChild(node);
    };
  };
}

// output/Web.DOM.Node/index.js
var map16 = /* @__PURE__ */ map(functorEffect);
var parentNode2 = /* @__PURE__ */ (function() {
  var $6 = map16(toMaybe);
  return function($7) {
    return $6(_parentNode($7));
  };
})();
var nextSibling = /* @__PURE__ */ (function() {
  var $15 = map16(toMaybe);
  return function($16) {
    return $15(_nextSibling($16));
  };
})();

// output/Halogen.VDom.Driver/index.js
var $runtime_lazy8 = function(name15, moduleName, init4) {
  var state3 = 0;
  var val;
  return function(lineNumber) {
    if (state3 === 2) return val;
    if (state3 === 1) throw new ReferenceError(name15 + " was needed before it finished initializing (module " + moduleName + ", line " + lineNumber + ")", moduleName, lineNumber);
    state3 = 1;
    val = init4();
    state3 = 2;
    return val;
  };
};
var $$void6 = /* @__PURE__ */ $$void(functorEffect);
var pure8 = /* @__PURE__ */ pure(applicativeEffect);
var traverse_6 = /* @__PURE__ */ traverse_(applicativeEffect)(foldableMaybe);
var unwrap2 = /* @__PURE__ */ unwrap();
var when3 = /* @__PURE__ */ when(applicativeEffect);
var not2 = /* @__PURE__ */ not(/* @__PURE__ */ heytingAlgebraFunction(/* @__PURE__ */ heytingAlgebraFunction(heytingAlgebraBoolean)));
var identity8 = /* @__PURE__ */ identity(categoryFn);
var bind14 = /* @__PURE__ */ bind(bindAff);
var liftEffect6 = /* @__PURE__ */ liftEffect(monadEffectAff);
var map17 = /* @__PURE__ */ map(functorEffect);
var bindFlipped7 = /* @__PURE__ */ bindFlipped(bindEffect);
var substInParent = function(v) {
  return function(v1) {
    return function(v2) {
      if (v1 instanceof Just && v2 instanceof Just) {
        return $$void6(insertBefore(v)(v1.value0)(v2.value0));
      }
      ;
      if (v1 instanceof Nothing && v2 instanceof Just) {
        return $$void6(appendChild(v)(v2.value0));
      }
      ;
      return pure8(unit);
    };
  };
};
var removeChild3 = function(v) {
  return function __do2() {
    var npn = parentNode2(v.node)();
    return traverse_6(function(pn) {
      return removeChild2(v.node)(pn);
    })(npn)();
  };
};
var mkSpec = function(handler3) {
  return function(renderChildRef) {
    return function(document3) {
      var getNode = unRenderStateX(function(v) {
        return v.node;
      });
      var done = function(st) {
        if (st instanceof Just) {
          return halt(st.value0);
        }
        ;
        return unit;
      };
      var buildWidget2 = function(spec) {
        var buildThunk2 = buildThunk(unwrap2)(spec);
        var $lazy_patch = $runtime_lazy8("patch", "Halogen.VDom.Driver", function() {
          return function(st, slot) {
            if (st instanceof Just) {
              if (slot instanceof ComponentSlot) {
                halt(st.value0);
                return $lazy_renderComponentSlot(100)(slot.value0);
              }
              ;
              if (slot instanceof ThunkSlot) {
                var step$prime = step2(st.value0, slot.value0);
                return mkStep(new Step(extract2(step$prime), new Just(step$prime), $lazy_patch(103), done));
              }
              ;
              throw new Error("Failed pattern match at Halogen.VDom.Driver (line 97, column 22 - line 103, column 79): " + [slot.constructor.name]);
            }
            ;
            return $lazy_render(104)(slot);
          };
        });
        var $lazy_render = $runtime_lazy8("render", "Halogen.VDom.Driver", function() {
          return function(slot) {
            if (slot instanceof ComponentSlot) {
              return $lazy_renderComponentSlot(86)(slot.value0);
            }
            ;
            if (slot instanceof ThunkSlot) {
              var step3 = buildThunk2(slot.value0);
              return mkStep(new Step(extract2(step3), new Just(step3), $lazy_patch(89), done));
            }
            ;
            throw new Error("Failed pattern match at Halogen.VDom.Driver (line 84, column 7 - line 89, column 75): " + [slot.constructor.name]);
          };
        });
        var $lazy_renderComponentSlot = $runtime_lazy8("renderComponentSlot", "Halogen.VDom.Driver", function() {
          return function(cs) {
            var renderChild = read(renderChildRef)();
            var rsx = renderChild(cs)();
            var node = getNode(rsx);
            return mkStep(new Step(node, Nothing.value, $lazy_patch(117), done));
          };
        });
        var patch = $lazy_patch(91);
        var render2 = $lazy_render(82);
        var renderComponentSlot = $lazy_renderComponentSlot(109);
        return render2;
      };
      var buildAttributes = buildProp(handler3);
      return {
        buildWidget: buildWidget2,
        buildAttributes,
        document: document3
      };
    };
  };
};
var renderSpec = function(document3) {
  return function(container) {
    var render2 = function(handler3) {
      return function(child) {
        return function(v) {
          return function(v1) {
            if (v1 instanceof Nothing) {
              return function __do2() {
                var renderChildRef = $$new(child)();
                var spec = mkSpec(handler3)(renderChildRef)(document3);
                var machine = buildVDom(spec)(v);
                var node = extract2(machine);
                $$void6(appendChild(node)(toNode(container)))();
                return {
                  machine,
                  node,
                  renderChildRef
                };
              };
            }
            ;
            if (v1 instanceof Just) {
              return function __do2() {
                write(child)(v1.value0.renderChildRef)();
                var parent2 = parentNode2(v1.value0.node)();
                var nextSib = nextSibling(v1.value0.node)();
                var machine$prime = step2(v1.value0.machine, v);
                var newNode = extract2(machine$prime);
                when3(not2(unsafeRefEq)(v1.value0.node)(newNode))(substInParent(newNode)(nextSib)(parent2))();
                return {
                  machine: machine$prime,
                  node: newNode,
                  renderChildRef: v1.value0.renderChildRef
                };
              };
            }
            ;
            throw new Error("Failed pattern match at Halogen.VDom.Driver (line 157, column 5 - line 173, column 80): " + [v1.constructor.name]);
          };
        };
      };
    };
    return {
      render: render2,
      renderChild: identity8,
      removeChild: removeChild3,
      dispose: removeChild3
    };
  };
};
var runUI2 = function(component2) {
  return function(i2) {
    return function(element3) {
      return bind14(liftEffect6(map17(toDocument)(bindFlipped7(document2)(windowImpl))))(function(document3) {
        return runUI(renderSpec(document3)(element3))(component2)(i2);
      });
    };
  };
};

// output/PSD3.Internal.Selection.Types/index.js
var EmptySelection = /* @__PURE__ */ (function() {
  function EmptySelection2(value0) {
    this.value0 = value0;
  }
  ;
  EmptySelection2.create = function(value0) {
    return new EmptySelection2(value0);
  };
  return EmptySelection2;
})();
var BoundSelection = /* @__PURE__ */ (function() {
  function BoundSelection2(value0) {
    this.value0 = value0;
  }
  ;
  BoundSelection2.create = function(value0) {
    return new BoundSelection2(value0);
  };
  return BoundSelection2;
})();
var PendingSelection = /* @__PURE__ */ (function() {
  function PendingSelection2(value0) {
    this.value0 = value0;
  }
  ;
  PendingSelection2.create = function(value0) {
    return new PendingSelection2(value0);
  };
  return PendingSelection2;
})();
var ExitingSelection = /* @__PURE__ */ (function() {
  function ExitingSelection2(value0) {
    this.value0 = value0;
  }
  ;
  ExitingSelection2.create = function(value0) {
    return new ExitingSelection2(value0);
  };
  return ExitingSelection2;
})();
var SVGContext = /* @__PURE__ */ (function() {
  function SVGContext2() {
  }
  ;
  SVGContext2.value = new SVGContext2();
  return SVGContext2;
})();
var HTMLContext = /* @__PURE__ */ (function() {
  function HTMLContext2() {
  }
  ;
  HTMLContext2.value = new HTMLContext2();
  return HTMLContext2;
})();
var JoinResult = /* @__PURE__ */ (function() {
  function JoinResult2(value0) {
    this.value0 = value0;
  }
  ;
  JoinResult2.create = function(value0) {
    return new JoinResult2(value0);
  };
  return JoinResult2;
})();
var Circle = /* @__PURE__ */ (function() {
  function Circle3() {
  }
  ;
  Circle3.value = new Circle3();
  return Circle3;
})();
var Rect = /* @__PURE__ */ (function() {
  function Rect2() {
  }
  ;
  Rect2.value = new Rect2();
  return Rect2;
})();
var Path = /* @__PURE__ */ (function() {
  function Path2() {
  }
  ;
  Path2.value = new Path2();
  return Path2;
})();
var Line = /* @__PURE__ */ (function() {
  function Line2() {
  }
  ;
  Line2.value = new Line2();
  return Line2;
})();
var Text2 = /* @__PURE__ */ (function() {
  function Text3() {
  }
  ;
  Text3.value = new Text3();
  return Text3;
})();
var Group = /* @__PURE__ */ (function() {
  function Group2() {
  }
  ;
  Group2.value = new Group2();
  return Group2;
})();
var SVG = /* @__PURE__ */ (function() {
  function SVG2() {
  }
  ;
  SVG2.value = new SVG2();
  return SVG2;
})();
var Defs = /* @__PURE__ */ (function() {
  function Defs2() {
  }
  ;
  Defs2.value = new Defs2();
  return Defs2;
})();
var LinearGradient = /* @__PURE__ */ (function() {
  function LinearGradient2() {
  }
  ;
  LinearGradient2.value = new LinearGradient2();
  return LinearGradient2;
})();
var Stop = /* @__PURE__ */ (function() {
  function Stop2() {
  }
  ;
  Stop2.value = new Stop2();
  return Stop2;
})();
var PatternFill = /* @__PURE__ */ (function() {
  function PatternFill2() {
  }
  ;
  PatternFill2.value = new PatternFill2();
  return PatternFill2;
})();
var Div = /* @__PURE__ */ (function() {
  function Div2() {
  }
  ;
  Div2.value = new Div2();
  return Div2;
})();
var Span = /* @__PURE__ */ (function() {
  function Span2() {
  }
  ;
  Span2.value = new Span2();
  return Span2;
})();
var Table = /* @__PURE__ */ (function() {
  function Table2() {
  }
  ;
  Table2.value = new Table2();
  return Table2;
})();
var Tr = /* @__PURE__ */ (function() {
  function Tr2() {
  }
  ;
  Tr2.value = new Tr2();
  return Tr2;
})();
var Td = /* @__PURE__ */ (function() {
  function Td2() {
  }
  ;
  Td2.value = new Td2();
  return Td2;
})();
var Th = /* @__PURE__ */ (function() {
  function Th2() {
  }
  ;
  Th2.value = new Th2();
  return Th2;
})();
var Tbody = /* @__PURE__ */ (function() {
  function Tbody2() {
  }
  ;
  Tbody2.value = new Tbody2();
  return Tbody2;
})();
var Thead = /* @__PURE__ */ (function() {
  function Thead2() {
  }
  ;
  Thead2.value = new Thead2();
  return Thead2;
})();
var elementContext = function(v) {
  if (v instanceof Circle) {
    return SVGContext.value;
  }
  ;
  if (v instanceof Rect) {
    return SVGContext.value;
  }
  ;
  if (v instanceof Path) {
    return SVGContext.value;
  }
  ;
  if (v instanceof Line) {
    return SVGContext.value;
  }
  ;
  if (v instanceof Text2) {
    return SVGContext.value;
  }
  ;
  if (v instanceof Group) {
    return SVGContext.value;
  }
  ;
  if (v instanceof SVG) {
    return SVGContext.value;
  }
  ;
  if (v instanceof Defs) {
    return SVGContext.value;
  }
  ;
  if (v instanceof LinearGradient) {
    return SVGContext.value;
  }
  ;
  if (v instanceof Stop) {
    return SVGContext.value;
  }
  ;
  if (v instanceof PatternFill) {
    return SVGContext.value;
  }
  ;
  if (v instanceof Div) {
    return HTMLContext.value;
  }
  ;
  if (v instanceof Span) {
    return HTMLContext.value;
  }
  ;
  if (v instanceof Table) {
    return HTMLContext.value;
  }
  ;
  if (v instanceof Tr) {
    return HTMLContext.value;
  }
  ;
  if (v instanceof Td) {
    return HTMLContext.value;
  }
  ;
  if (v instanceof Th) {
    return HTMLContext.value;
  }
  ;
  if (v instanceof Tbody) {
    return HTMLContext.value;
  }
  ;
  if (v instanceof Thead) {
    return HTMLContext.value;
  }
  ;
  throw new Error("Failed pattern match at PSD3.Internal.Selection.Types (line 205, column 1 - line 205, column 47): " + [v.constructor.name]);
};

// output/PSD3.AST/index.js
var append6 = /* @__PURE__ */ append(semigroupArray);
var Node2 = /* @__PURE__ */ (function() {
  function Node3(value0) {
    this.value0 = value0;
  }
  ;
  Node3.create = function(value0) {
    return new Node3(value0);
  };
  return Node3;
})();
var Join2 = /* @__PURE__ */ (function() {
  function Join3(value0) {
    this.value0 = value0;
  }
  ;
  Join3.create = function(value0) {
    return new Join3(value0);
  };
  return Join3;
})();
var NestedJoin = /* @__PURE__ */ (function() {
  function NestedJoin2(value0) {
    this.value0 = value0;
  }
  ;
  NestedJoin2.create = function(value0) {
    return new NestedJoin2(value0);
  };
  return NestedJoin2;
})();
var UpdateJoin = /* @__PURE__ */ (function() {
  function UpdateJoin2(value0) {
    this.value0 = value0;
  }
  ;
  UpdateJoin2.create = function(value0) {
    return new UpdateJoin2(value0);
  };
  return UpdateJoin2;
})();
var UpdateNestedJoin = /* @__PURE__ */ (function() {
  function UpdateNestedJoin2(value0) {
    this.value0 = value0;
  }
  ;
  UpdateNestedJoin2.create = function(value0) {
    return new UpdateNestedJoin2(value0);
  };
  return UpdateNestedJoin2;
})();
var ConditionalRender = /* @__PURE__ */ (function() {
  function ConditionalRender2(value0) {
    this.value0 = value0;
  }
  ;
  ConditionalRender2.create = function(value0) {
    return new ConditionalRender2(value0);
  };
  return ConditionalRender2;
})();
var LocalCoordSpace = /* @__PURE__ */ (function() {
  function LocalCoordSpace2(value0) {
    this.value0 = value0;
  }
  ;
  LocalCoordSpace2.create = function(value0) {
    return new LocalCoordSpace2(value0);
  };
  return LocalCoordSpace2;
})();
var withChildren = function(parent2) {
  return function(newChildren) {
    if (parent2 instanceof Node2) {
      return new Node2({
        name: parent2.value0.name,
        elemType: parent2.value0.elemType,
        attrs: parent2.value0.attrs,
        behaviors: parent2.value0.behaviors,
        children: append6(parent2.value0.children)(newChildren)
      });
    }
    ;
    if (parent2 instanceof Join2) {
      return new Join2(parent2.value0);
    }
    ;
    if (parent2 instanceof NestedJoin) {
      return new NestedJoin(parent2.value0);
    }
    ;
    if (parent2 instanceof UpdateJoin) {
      return new UpdateJoin(parent2.value0);
    }
    ;
    if (parent2 instanceof UpdateNestedJoin) {
      return new UpdateNestedJoin(parent2.value0);
    }
    ;
    if (parent2 instanceof ConditionalRender) {
      return new ConditionalRender(parent2.value0);
    }
    ;
    if (parent2 instanceof LocalCoordSpace) {
      return new LocalCoordSpace(parent2.value0);
    }
    ;
    throw new Error("Failed pattern match at PSD3.AST (line 295, column 35 - line 302, column 45): " + [parent2.constructor.name]);
  };
};
var withChild = function(parent2) {
  return function(child) {
    if (parent2 instanceof Node2) {
      return new Node2({
        name: parent2.value0.name,
        elemType: parent2.value0.elemType,
        attrs: parent2.value0.attrs,
        behaviors: parent2.value0.behaviors,
        children: append6(parent2.value0.children)([child])
      });
    }
    ;
    if (parent2 instanceof Join2) {
      return new Join2(parent2.value0);
    }
    ;
    if (parent2 instanceof NestedJoin) {
      return new NestedJoin(parent2.value0);
    }
    ;
    if (parent2 instanceof UpdateJoin) {
      return new UpdateJoin(parent2.value0);
    }
    ;
    if (parent2 instanceof UpdateNestedJoin) {
      return new UpdateNestedJoin(parent2.value0);
    }
    ;
    if (parent2 instanceof ConditionalRender) {
      return new ConditionalRender(parent2.value0);
    }
    ;
    if (parent2 instanceof LocalCoordSpace) {
      return new LocalCoordSpace(parent2.value0);
    }
    ;
    throw new Error("Failed pattern match at PSD3.AST (line 282, column 26 - line 289, column 45): " + [parent2.constructor.name]);
  };
};
var named = function(elemType) {
  return function(name15) {
    return function(attrs) {
      return new Node2({
        name: new Just(name15),
        elemType,
        attrs,
        behaviors: [],
        children: []
      });
    };
  };
};
var elem2 = function(elemType) {
  return function(attrs) {
    return new Node2({
      name: Nothing.value,
      elemType,
      attrs,
      behaviors: [],
      children: []
    });
  };
};

// output/Data.String.CodePoints/foreign.js
var hasStringIterator = typeof Symbol !== "undefined" && Symbol != null && typeof Symbol.iterator !== "undefined" && typeof String.prototype[Symbol.iterator] === "function";
var hasFromCodePoint = typeof String.prototype.fromCodePoint === "function";
var hasCodePointAt = typeof String.prototype.codePointAt === "function";

// output/PSD3.Expr.Expr/index.js
var str = function(dict) {
  return dict.str;
};
var lit = function(dict) {
  return dict.lit;
};

// output/PSD3.Expr.Interpreter.Eval/index.js
var stringExprEvalD = {
  str: function(s) {
    return function(v) {
      return function(v1) {
        return s;
      };
    };
  },
  concat: function(v) {
    return function(v1) {
      return function(d) {
        return function(i2) {
          return v(d)(i2) + v1(d)(i2);
        };
      };
    };
  }
};
var runEvalD = function(v) {
  return function(d) {
    return function(i2) {
      return v(d)(i2);
    };
  };
};
var numExprEvalD = {
  lit: function(n) {
    return function(v) {
      return function(v1) {
        return n;
      };
    };
  },
  add: function(v) {
    return function(v1) {
      return function(d) {
        return function(i2) {
          return v(d)(i2) + v1(d)(i2);
        };
      };
    };
  },
  sub: function(v) {
    return function(v1) {
      return function(d) {
        return function(i2) {
          return v(d)(i2) - v1(d)(i2);
        };
      };
    };
  },
  mul: function(v) {
    return function(v1) {
      return function(d) {
        return function(i2) {
          return v(d)(i2) * v1(d)(i2);
        };
      };
    };
  },
  div: function(v) {
    return function(v1) {
      return function(d) {
        return function(i2) {
          return v(d)(i2) / v1(d)(i2);
        };
      };
    };
  },
  negate: function(v) {
    return function(d) {
      return function(i2) {
        return -v(d)(i2);
      };
    };
  }
};

// output/PSD3.Internal.Attribute/index.js
var StringValue = /* @__PURE__ */ (function() {
  function StringValue2(value0) {
    this.value0 = value0;
  }
  ;
  StringValue2.create = function(value0) {
    return new StringValue2(value0);
  };
  return StringValue2;
})();
var NumberValue = /* @__PURE__ */ (function() {
  function NumberValue2(value0) {
    this.value0 = value0;
  }
  ;
  NumberValue2.create = function(value0) {
    return new NumberValue2(value0);
  };
  return NumberValue2;
})();
var BooleanValue = /* @__PURE__ */ (function() {
  function BooleanValue2(value0) {
    this.value0 = value0;
  }
  ;
  BooleanValue2.create = function(value0) {
    return new BooleanValue2(value0);
  };
  return BooleanValue2;
})();
var UnknownSource = /* @__PURE__ */ (function() {
  function UnknownSource2() {
  }
  ;
  UnknownSource2.value = new UnknownSource2();
  return UnknownSource2;
})();
var StaticAttr = /* @__PURE__ */ (function() {
  function StaticAttr2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  ;
  StaticAttr2.create = function(value0) {
    return function(value1) {
      return new StaticAttr2(value0, value1);
    };
  };
  return StaticAttr2;
})();
var DataAttr = /* @__PURE__ */ (function() {
  function DataAttr2(value0, value1, value22) {
    this.value0 = value0;
    this.value1 = value1;
    this.value2 = value22;
  }
  ;
  DataAttr2.create = function(value0) {
    return function(value1) {
      return function(value22) {
        return new DataAttr2(value0, value1, value22);
      };
    };
  };
  return DataAttr2;
})();
var IndexedAttr = /* @__PURE__ */ (function() {
  function IndexedAttr2(value0, value1, value22) {
    this.value0 = value0;
    this.value1 = value1;
    this.value2 = value22;
  }
  ;
  IndexedAttr2.create = function(value0) {
    return function(value1) {
      return function(value22) {
        return new IndexedAttr2(value0, value1, value22);
      };
    };
  };
  return IndexedAttr2;
})();

// output/PSD3.Expr.Friendly/index.js
var show2 = /* @__PURE__ */ show(showNumber);
var toAttributeValueString = {
  toAttrValue: /* @__PURE__ */ identity(categoryFn)
};
var toAttributeValueNumber = {
  toAttrValue: show2
};
var viewBox = function(minX) {
  return function(minY) {
    return function(w) {
      return function(h) {
        return new StaticAttr("viewBox", new StringValue(show2(minX) + (" " + (show2(minY) + (" " + (show2(w) + (" " + show2(h))))))));
      };
    };
  };
};
var toAttrValue = function(dict) {
  return dict.toAttrValue;
};
var text6 = function(dictStringExpr) {
  return str(dictStringExpr);
};
var num = function(dictNumExpr) {
  return lit(dictNumExpr);
};
var attr3 = function(dictToAttributeValue) {
  var toAttrValue1 = toAttrValue(dictToAttributeValue);
  return function(name15) {
    return function(expr) {
      return new DataAttr(name15, UnknownSource.value, function(d) {
        return new StringValue(toAttrValue1(runEvalD(expr)(d)(0)));
      });
    };
  };
};
var fill = function(dictToAttributeValue) {
  return attr3(dictToAttributeValue)("fill");
};
var stroke = function(dictToAttributeValue) {
  return attr3(dictToAttributeValue)("stroke");
};
var strokeWidth = function(dictToAttributeValue) {
  return attr3(dictToAttributeValue)("stroke-width");
};
var textAnchor = function(dictToAttributeValue) {
  return attr3(dictToAttributeValue)("text-anchor");
};
var textContent2 = function(dictToAttributeValue) {
  return attr3(dictToAttributeValue)("textContent");
};
var transform = function(dictToAttributeValue) {
  return attr3(dictToAttributeValue)("transform");
};
var x = function(dictToAttributeValue) {
  return attr3(dictToAttributeValue)("x");
};
var x1 = function(dictToAttributeValue) {
  return attr3(dictToAttributeValue)("x1");
};
var x2 = function(dictToAttributeValue) {
  return attr3(dictToAttributeValue)("x2");
};
var y = function(dictToAttributeValue) {
  return attr3(dictToAttributeValue)("y");
};
var y1 = function(dictToAttributeValue) {
  return attr3(dictToAttributeValue)("y1");
};
var y2 = function(dictToAttributeValue) {
  return attr3(dictToAttributeValue)("y2");
};

// output/PSD3.Internal.Capabilities.Selection/index.js
var select5 = function(dict) {
  return dict.select;
};
var renderTree = function(dict) {
  return dict.renderTree;
};
var clear2 = function(dict) {
  return dict.clear;
};

// output/PSD3.Internal.Selection.Operations/foreign.js
function getElementData_(element3) {
  return function() {
    return element3.__data__;
  };
}
function setElementData_(datum2) {
  return function(element3) {
    return function() {
      element3.__data__ = datum2;
    };
  };
}
function setTextContent_(text8) {
  return function(element3) {
    return function() {
      element3.textContent = text8;
    };
  };
}
function offsetX(event) {
  return event.offsetX;
}
function offsetY(event) {
  return event.offsetY;
}
function clearElement_(selector) {
  return function() {
    const el = document.querySelector(selector);
    if (el) {
      el.innerHTML = "";
    }
  };
}
function jsonStringify_(value12) {
  return JSON.stringify(value12);
}

// output/Effect.Class.Console/index.js
var log3 = function(dictMonadEffect) {
  var $67 = liftEffect(dictMonadEffect);
  return function($68) {
    return $67(log2($68));
  };
};

// ../../../../../node_modules/d3-selection/src/namespaces.js
var xhtml = "http://www.w3.org/1999/xhtml";
var namespaces_default = {
  svg: "http://www.w3.org/2000/svg",
  xhtml,
  xlink: "http://www.w3.org/1999/xlink",
  xml: "http://www.w3.org/XML/1998/namespace",
  xmlns: "http://www.w3.org/2000/xmlns/"
};

// ../../../../../node_modules/d3-selection/src/namespace.js
function namespace_default(name15) {
  var prefix = name15 += "", i2 = prefix.indexOf(":");
  if (i2 >= 0 && (prefix = name15.slice(0, i2)) !== "xmlns") name15 = name15.slice(i2 + 1);
  return namespaces_default.hasOwnProperty(prefix) ? { space: namespaces_default[prefix], local: name15 } : name15;
}

// ../../../../../node_modules/d3-selection/src/creator.js
function creatorInherit(name15) {
  return function() {
    var document3 = this.ownerDocument, uri = this.namespaceURI;
    return uri === xhtml && document3.documentElement.namespaceURI === xhtml ? document3.createElement(name15) : document3.createElementNS(uri, name15);
  };
}
function creatorFixed(fullname) {
  return function() {
    return this.ownerDocument.createElementNS(fullname.space, fullname.local);
  };
}
function creator_default(name15) {
  var fullname = namespace_default(name15);
  return (fullname.local ? creatorFixed : creatorInherit)(fullname);
}

// ../../../../../node_modules/d3-selection/src/selector.js
function none2() {
}
function selector_default(selector) {
  return selector == null ? none2 : function() {
    return this.querySelector(selector);
  };
}

// ../../../../../node_modules/d3-selection/src/selection/select.js
function select_default(select9) {
  if (typeof select9 !== "function") select9 = selector_default(select9);
  for (var groups = this._groups, m = groups.length, subgroups = new Array(m), j = 0; j < m; ++j) {
    for (var group4 = groups[j], n = group4.length, subgroup = subgroups[j] = new Array(n), node, subnode, i2 = 0; i2 < n; ++i2) {
      if ((node = group4[i2]) && (subnode = select9.call(node, node.__data__, i2, group4))) {
        if ("__data__" in node) subnode.__data__ = node.__data__;
        subgroup[i2] = subnode;
      }
    }
  }
  return new Selection(subgroups, this._parents);
}

// ../../../../../node_modules/d3-selection/src/array.js
function array(x4) {
  return x4 == null ? [] : Array.isArray(x4) ? x4 : Array.from(x4);
}

// ../../../../../node_modules/d3-selection/src/selectorAll.js
function empty7() {
  return [];
}
function selectorAll_default(selector) {
  return selector == null ? empty7 : function() {
    return this.querySelectorAll(selector);
  };
}

// ../../../../../node_modules/d3-selection/src/selection/selectAll.js
function arrayAll(select9) {
  return function() {
    return array(select9.apply(this, arguments));
  };
}
function selectAll_default(select9) {
  if (typeof select9 === "function") select9 = arrayAll(select9);
  else select9 = selectorAll_default(select9);
  for (var groups = this._groups, m = groups.length, subgroups = [], parents = [], j = 0; j < m; ++j) {
    for (var group4 = groups[j], n = group4.length, node, i2 = 0; i2 < n; ++i2) {
      if (node = group4[i2]) {
        subgroups.push(select9.call(node, node.__data__, i2, group4));
        parents.push(node);
      }
    }
  }
  return new Selection(subgroups, parents);
}

// ../../../../../node_modules/d3-selection/src/matcher.js
function matcher_default(selector) {
  return function() {
    return this.matches(selector);
  };
}
function childMatcher(selector) {
  return function(node) {
    return node.matches(selector);
  };
}

// ../../../../../node_modules/d3-selection/src/selection/selectChild.js
var find3 = Array.prototype.find;
function childFind(match2) {
  return function() {
    return find3.call(this.children, match2);
  };
}
function childFirst() {
  return this.firstElementChild;
}
function selectChild_default(match2) {
  return this.select(match2 == null ? childFirst : childFind(typeof match2 === "function" ? match2 : childMatcher(match2)));
}

// ../../../../../node_modules/d3-selection/src/selection/selectChildren.js
var filter3 = Array.prototype.filter;
function children2() {
  return Array.from(this.children);
}
function childrenFilter(match2) {
  return function() {
    return filter3.call(this.children, match2);
  };
}
function selectChildren_default(match2) {
  return this.selectAll(match2 == null ? children2 : childrenFilter(typeof match2 === "function" ? match2 : childMatcher(match2)));
}

// ../../../../../node_modules/d3-selection/src/selection/filter.js
function filter_default(match2) {
  if (typeof match2 !== "function") match2 = matcher_default(match2);
  for (var groups = this._groups, m = groups.length, subgroups = new Array(m), j = 0; j < m; ++j) {
    for (var group4 = groups[j], n = group4.length, subgroup = subgroups[j] = [], node, i2 = 0; i2 < n; ++i2) {
      if ((node = group4[i2]) && match2.call(node, node.__data__, i2, group4)) {
        subgroup.push(node);
      }
    }
  }
  return new Selection(subgroups, this._parents);
}

// ../../../../../node_modules/d3-selection/src/selection/sparse.js
function sparse_default(update) {
  return new Array(update.length);
}

// ../../../../../node_modules/d3-selection/src/selection/enter.js
function enter_default() {
  return new Selection(this._enter || this._groups.map(sparse_default), this._parents);
}
function EnterNode(parent2, datum2) {
  this.ownerDocument = parent2.ownerDocument;
  this.namespaceURI = parent2.namespaceURI;
  this._next = null;
  this._parent = parent2;
  this.__data__ = datum2;
}
EnterNode.prototype = {
  constructor: EnterNode,
  appendChild: function(child) {
    return this._parent.insertBefore(child, this._next);
  },
  insertBefore: function(child, next) {
    return this._parent.insertBefore(child, next);
  },
  querySelector: function(selector) {
    return this._parent.querySelector(selector);
  },
  querySelectorAll: function(selector) {
    return this._parent.querySelectorAll(selector);
  }
};

// ../../../../../node_modules/d3-selection/src/constant.js
function constant_default(x4) {
  return function() {
    return x4;
  };
}

// ../../../../../node_modules/d3-selection/src/selection/data.js
function bindIndex(parent2, group4, enter, update, exit, data) {
  var i2 = 0, node, groupLength = group4.length, dataLength = data.length;
  for (; i2 < dataLength; ++i2) {
    if (node = group4[i2]) {
      node.__data__ = data[i2];
      update[i2] = node;
    } else {
      enter[i2] = new EnterNode(parent2, data[i2]);
    }
  }
  for (; i2 < groupLength; ++i2) {
    if (node = group4[i2]) {
      exit[i2] = node;
    }
  }
}
function bindKey(parent2, group4, enter, update, exit, data, key) {
  var i2, node, nodeByKeyValue = /* @__PURE__ */ new Map(), groupLength = group4.length, dataLength = data.length, keyValues = new Array(groupLength), keyValue;
  for (i2 = 0; i2 < groupLength; ++i2) {
    if (node = group4[i2]) {
      keyValues[i2] = keyValue = key.call(node, node.__data__, i2, group4) + "";
      if (nodeByKeyValue.has(keyValue)) {
        exit[i2] = node;
      } else {
        nodeByKeyValue.set(keyValue, node);
      }
    }
  }
  for (i2 = 0; i2 < dataLength; ++i2) {
    keyValue = key.call(parent2, data[i2], i2, data) + "";
    if (node = nodeByKeyValue.get(keyValue)) {
      update[i2] = node;
      node.__data__ = data[i2];
      nodeByKeyValue.delete(keyValue);
    } else {
      enter[i2] = new EnterNode(parent2, data[i2]);
    }
  }
  for (i2 = 0; i2 < groupLength; ++i2) {
    if ((node = group4[i2]) && nodeByKeyValue.get(keyValues[i2]) === node) {
      exit[i2] = node;
    }
  }
}
function datum(node) {
  return node.__data__;
}
function data_default(value12, key) {
  if (!arguments.length) return Array.from(this, datum);
  var bind7 = key ? bindKey : bindIndex, parents = this._parents, groups = this._groups;
  if (typeof value12 !== "function") value12 = constant_default(value12);
  for (var m = groups.length, update = new Array(m), enter = new Array(m), exit = new Array(m), j = 0; j < m; ++j) {
    var parent2 = parents[j], group4 = groups[j], groupLength = group4.length, data = arraylike(value12.call(parent2, parent2 && parent2.__data__, j, parents)), dataLength = data.length, enterGroup = enter[j] = new Array(dataLength), updateGroup = update[j] = new Array(dataLength), exitGroup = exit[j] = new Array(groupLength);
    bind7(parent2, group4, enterGroup, updateGroup, exitGroup, data, key);
    for (var i0 = 0, i1 = 0, previous, next; i0 < dataLength; ++i0) {
      if (previous = enterGroup[i0]) {
        if (i0 >= i1) i1 = i0 + 1;
        while (!(next = updateGroup[i1]) && ++i1 < dataLength) ;
        previous._next = next || null;
      }
    }
  }
  update = new Selection(update, parents);
  update._enter = enter;
  update._exit = exit;
  return update;
}
function arraylike(data) {
  return typeof data === "object" && "length" in data ? data : Array.from(data);
}

// ../../../../../node_modules/d3-selection/src/selection/exit.js
function exit_default() {
  return new Selection(this._exit || this._groups.map(sparse_default), this._parents);
}

// ../../../../../node_modules/d3-selection/src/selection/join.js
function join_default(onenter, onupdate, onexit) {
  var enter = this.enter(), update = this, exit = this.exit();
  if (typeof onenter === "function") {
    enter = onenter(enter);
    if (enter) enter = enter.selection();
  } else {
    enter = enter.append(onenter + "");
  }
  if (onupdate != null) {
    update = onupdate(update);
    if (update) update = update.selection();
  }
  if (onexit == null) exit.remove();
  else onexit(exit);
  return enter && update ? enter.merge(update).order() : update;
}

// ../../../../../node_modules/d3-selection/src/selection/merge.js
function merge_default(context) {
  var selection2 = context.selection ? context.selection() : context;
  for (var groups0 = this._groups, groups1 = selection2._groups, m0 = groups0.length, m1 = groups1.length, m = Math.min(m0, m1), merges = new Array(m0), j = 0; j < m; ++j) {
    for (var group0 = groups0[j], group1 = groups1[j], n = group0.length, merge3 = merges[j] = new Array(n), node, i2 = 0; i2 < n; ++i2) {
      if (node = group0[i2] || group1[i2]) {
        merge3[i2] = node;
      }
    }
  }
  for (; j < m0; ++j) {
    merges[j] = groups0[j];
  }
  return new Selection(merges, this._parents);
}

// ../../../../../node_modules/d3-selection/src/selection/order.js
function order_default() {
  for (var groups = this._groups, j = -1, m = groups.length; ++j < m; ) {
    for (var group4 = groups[j], i2 = group4.length - 1, next = group4[i2], node; --i2 >= 0; ) {
      if (node = group4[i2]) {
        if (next && node.compareDocumentPosition(next) ^ 4) next.parentNode.insertBefore(node, next);
        next = node;
      }
    }
  }
  return this;
}

// ../../../../../node_modules/d3-selection/src/selection/sort.js
function sort_default(compare3) {
  if (!compare3) compare3 = ascending;
  function compareNode(a2, b10) {
    return a2 && b10 ? compare3(a2.__data__, b10.__data__) : !a2 - !b10;
  }
  for (var groups = this._groups, m = groups.length, sortgroups = new Array(m), j = 0; j < m; ++j) {
    for (var group4 = groups[j], n = group4.length, sortgroup = sortgroups[j] = new Array(n), node, i2 = 0; i2 < n; ++i2) {
      if (node = group4[i2]) {
        sortgroup[i2] = node;
      }
    }
    sortgroup.sort(compareNode);
  }
  return new Selection(sortgroups, this._parents).order();
}
function ascending(a2, b10) {
  return a2 < b10 ? -1 : a2 > b10 ? 1 : a2 >= b10 ? 0 : NaN;
}

// ../../../../../node_modules/d3-selection/src/selection/call.js
function call_default() {
  var callback = arguments[0];
  arguments[0] = this;
  callback.apply(null, arguments);
  return this;
}

// ../../../../../node_modules/d3-selection/src/selection/nodes.js
function nodes_default() {
  return Array.from(this);
}

// ../../../../../node_modules/d3-selection/src/selection/node.js
function node_default() {
  for (var groups = this._groups, j = 0, m = groups.length; j < m; ++j) {
    for (var group4 = groups[j], i2 = 0, n = group4.length; i2 < n; ++i2) {
      var node = group4[i2];
      if (node) return node;
    }
  }
  return null;
}

// ../../../../../node_modules/d3-selection/src/selection/size.js
function size_default() {
  let size4 = 0;
  for (const node of this) ++size4;
  return size4;
}

// ../../../../../node_modules/d3-selection/src/selection/empty.js
function empty_default() {
  return !this.node();
}

// ../../../../../node_modules/d3-selection/src/selection/each.js
function each_default(callback) {
  for (var groups = this._groups, j = 0, m = groups.length; j < m; ++j) {
    for (var group4 = groups[j], i2 = 0, n = group4.length, node; i2 < n; ++i2) {
      if (node = group4[i2]) callback.call(node, node.__data__, i2, group4);
    }
  }
  return this;
}

// ../../../../../node_modules/d3-selection/src/selection/attr.js
function attrRemove(name15) {
  return function() {
    this.removeAttribute(name15);
  };
}
function attrRemoveNS(fullname) {
  return function() {
    this.removeAttributeNS(fullname.space, fullname.local);
  };
}
function attrConstant(name15, value12) {
  return function() {
    this.setAttribute(name15, value12);
  };
}
function attrConstantNS(fullname, value12) {
  return function() {
    this.setAttributeNS(fullname.space, fullname.local, value12);
  };
}
function attrFunction(name15, value12) {
  return function() {
    var v = value12.apply(this, arguments);
    if (v == null) this.removeAttribute(name15);
    else this.setAttribute(name15, v);
  };
}
function attrFunctionNS(fullname, value12) {
  return function() {
    var v = value12.apply(this, arguments);
    if (v == null) this.removeAttributeNS(fullname.space, fullname.local);
    else this.setAttributeNS(fullname.space, fullname.local, v);
  };
}
function attr_default(name15, value12) {
  var fullname = namespace_default(name15);
  if (arguments.length < 2) {
    var node = this.node();
    return fullname.local ? node.getAttributeNS(fullname.space, fullname.local) : node.getAttribute(fullname);
  }
  return this.each((value12 == null ? fullname.local ? attrRemoveNS : attrRemove : typeof value12 === "function" ? fullname.local ? attrFunctionNS : attrFunction : fullname.local ? attrConstantNS : attrConstant)(fullname, value12));
}

// ../../../../../node_modules/d3-selection/src/window.js
function window_default(node) {
  return node.ownerDocument && node.ownerDocument.defaultView || node.document && node || node.defaultView;
}

// ../../../../../node_modules/d3-selection/src/selection/style.js
function styleRemove(name15) {
  return function() {
    this.style.removeProperty(name15);
  };
}
function styleConstant(name15, value12, priority) {
  return function() {
    this.style.setProperty(name15, value12, priority);
  };
}
function styleFunction(name15, value12, priority) {
  return function() {
    var v = value12.apply(this, arguments);
    if (v == null) this.style.removeProperty(name15);
    else this.style.setProperty(name15, v, priority);
  };
}
function style_default(name15, value12, priority) {
  return arguments.length > 1 ? this.each((value12 == null ? styleRemove : typeof value12 === "function" ? styleFunction : styleConstant)(name15, value12, priority == null ? "" : priority)) : styleValue(this.node(), name15);
}
function styleValue(node, name15) {
  return node.style.getPropertyValue(name15) || window_default(node).getComputedStyle(node, null).getPropertyValue(name15);
}

// ../../../../../node_modules/d3-selection/src/selection/property.js
function propertyRemove(name15) {
  return function() {
    delete this[name15];
  };
}
function propertyConstant(name15, value12) {
  return function() {
    this[name15] = value12;
  };
}
function propertyFunction(name15, value12) {
  return function() {
    var v = value12.apply(this, arguments);
    if (v == null) delete this[name15];
    else this[name15] = v;
  };
}
function property_default(name15, value12) {
  return arguments.length > 1 ? this.each((value12 == null ? propertyRemove : typeof value12 === "function" ? propertyFunction : propertyConstant)(name15, value12)) : this.node()[name15];
}

// ../../../../../node_modules/d3-selection/src/selection/classed.js
function classArray(string) {
  return string.trim().split(/^|\s+/);
}
function classList2(node) {
  return node.classList || new ClassList(node);
}
function ClassList(node) {
  this._node = node;
  this._names = classArray(node.getAttribute("class") || "");
}
ClassList.prototype = {
  add: function(name15) {
    var i2 = this._names.indexOf(name15);
    if (i2 < 0) {
      this._names.push(name15);
      this._node.setAttribute("class", this._names.join(" "));
    }
  },
  remove: function(name15) {
    var i2 = this._names.indexOf(name15);
    if (i2 >= 0) {
      this._names.splice(i2, 1);
      this._node.setAttribute("class", this._names.join(" "));
    }
  },
  contains: function(name15) {
    return this._names.indexOf(name15) >= 0;
  }
};
function classedAdd(node, names) {
  var list = classList2(node), i2 = -1, n = names.length;
  while (++i2 < n) list.add(names[i2]);
}
function classedRemove(node, names) {
  var list = classList2(node), i2 = -1, n = names.length;
  while (++i2 < n) list.remove(names[i2]);
}
function classedTrue(names) {
  return function() {
    classedAdd(this, names);
  };
}
function classedFalse(names) {
  return function() {
    classedRemove(this, names);
  };
}
function classedFunction(names, value12) {
  return function() {
    (value12.apply(this, arguments) ? classedAdd : classedRemove)(this, names);
  };
}
function classed_default(name15, value12) {
  var names = classArray(name15 + "");
  if (arguments.length < 2) {
    var list = classList2(this.node()), i2 = -1, n = names.length;
    while (++i2 < n) if (!list.contains(names[i2])) return false;
    return true;
  }
  return this.each((typeof value12 === "function" ? classedFunction : value12 ? classedTrue : classedFalse)(names, value12));
}

// ../../../../../node_modules/d3-selection/src/selection/text.js
function textRemove() {
  this.textContent = "";
}
function textConstant(value12) {
  return function() {
    this.textContent = value12;
  };
}
function textFunction(value12) {
  return function() {
    var v = value12.apply(this, arguments);
    this.textContent = v == null ? "" : v;
  };
}
function text_default(value12) {
  return arguments.length ? this.each(value12 == null ? textRemove : (typeof value12 === "function" ? textFunction : textConstant)(value12)) : this.node().textContent;
}

// ../../../../../node_modules/d3-selection/src/selection/html.js
function htmlRemove() {
  this.innerHTML = "";
}
function htmlConstant(value12) {
  return function() {
    this.innerHTML = value12;
  };
}
function htmlFunction(value12) {
  return function() {
    var v = value12.apply(this, arguments);
    this.innerHTML = v == null ? "" : v;
  };
}
function html_default(value12) {
  return arguments.length ? this.each(value12 == null ? htmlRemove : (typeof value12 === "function" ? htmlFunction : htmlConstant)(value12)) : this.node().innerHTML;
}

// ../../../../../node_modules/d3-selection/src/selection/raise.js
function raise2() {
  if (this.nextSibling) this.parentNode.appendChild(this);
}
function raise_default() {
  return this.each(raise2);
}

// ../../../../../node_modules/d3-selection/src/selection/lower.js
function lower() {
  if (this.previousSibling) this.parentNode.insertBefore(this, this.parentNode.firstChild);
}
function lower_default() {
  return this.each(lower);
}

// ../../../../../node_modules/d3-selection/src/selection/append.js
function append_default(name15) {
  var create6 = typeof name15 === "function" ? name15 : creator_default(name15);
  return this.select(function() {
    return this.appendChild(create6.apply(this, arguments));
  });
}

// ../../../../../node_modules/d3-selection/src/selection/insert.js
function constantNull() {
  return null;
}
function insert_default(name15, before) {
  var create6 = typeof name15 === "function" ? name15 : creator_default(name15), select9 = before == null ? constantNull : typeof before === "function" ? before : selector_default(before);
  return this.select(function() {
    return this.insertBefore(create6.apply(this, arguments), select9.apply(this, arguments) || null);
  });
}

// ../../../../../node_modules/d3-selection/src/selection/remove.js
function remove() {
  var parent2 = this.parentNode;
  if (parent2) parent2.removeChild(this);
}
function remove_default() {
  return this.each(remove);
}

// ../../../../../node_modules/d3-selection/src/selection/clone.js
function selection_cloneShallow() {
  var clone2 = this.cloneNode(false), parent2 = this.parentNode;
  return parent2 ? parent2.insertBefore(clone2, this.nextSibling) : clone2;
}
function selection_cloneDeep() {
  var clone2 = this.cloneNode(true), parent2 = this.parentNode;
  return parent2 ? parent2.insertBefore(clone2, this.nextSibling) : clone2;
}
function clone_default(deep) {
  return this.select(deep ? selection_cloneDeep : selection_cloneShallow);
}

// ../../../../../node_modules/d3-selection/src/selection/datum.js
function datum_default(value12) {
  return arguments.length ? this.property("__data__", value12) : this.node().__data__;
}

// ../../../../../node_modules/d3-selection/src/selection/on.js
function contextListener(listener) {
  return function(event) {
    listener.call(this, event, this.__data__);
  };
}
function parseTypenames(typenames) {
  return typenames.trim().split(/^|\s+/).map(function(t) {
    var name15 = "", i2 = t.indexOf(".");
    if (i2 >= 0) name15 = t.slice(i2 + 1), t = t.slice(0, i2);
    return { type: t, name: name15 };
  });
}
function onRemove(typename) {
  return function() {
    var on3 = this.__on;
    if (!on3) return;
    for (var j = 0, i2 = -1, m = on3.length, o; j < m; ++j) {
      if (o = on3[j], (!typename.type || o.type === typename.type) && o.name === typename.name) {
        this.removeEventListener(o.type, o.listener, o.options);
      } else {
        on3[++i2] = o;
      }
    }
    if (++i2) on3.length = i2;
    else delete this.__on;
  };
}
function onAdd(typename, value12, options2) {
  return function() {
    var on3 = this.__on, o, listener = contextListener(value12);
    if (on3) for (var j = 0, m = on3.length; j < m; ++j) {
      if ((o = on3[j]).type === typename.type && o.name === typename.name) {
        this.removeEventListener(o.type, o.listener, o.options);
        this.addEventListener(o.type, o.listener = listener, o.options = options2);
        o.value = value12;
        return;
      }
    }
    this.addEventListener(typename.type, listener, options2);
    o = { type: typename.type, name: typename.name, value: value12, listener, options: options2 };
    if (!on3) this.__on = [o];
    else on3.push(o);
  };
}
function on_default(typename, value12, options2) {
  var typenames = parseTypenames(typename + ""), i2, n = typenames.length, t;
  if (arguments.length < 2) {
    var on3 = this.node().__on;
    if (on3) for (var j = 0, m = on3.length, o; j < m; ++j) {
      for (i2 = 0, o = on3[j]; i2 < n; ++i2) {
        if ((t = typenames[i2]).type === o.type && t.name === o.name) {
          return o.value;
        }
      }
    }
    return;
  }
  on3 = value12 ? onAdd : onRemove;
  for (i2 = 0; i2 < n; ++i2) this.each(on3(typenames[i2], value12, options2));
  return this;
}

// ../../../../../node_modules/d3-selection/src/selection/dispatch.js
function dispatchEvent2(node, type, params) {
  var window2 = window_default(node), event = window2.CustomEvent;
  if (typeof event === "function") {
    event = new event(type, params);
  } else {
    event = window2.document.createEvent("Event");
    if (params) event.initEvent(type, params.bubbles, params.cancelable), event.detail = params.detail;
    else event.initEvent(type, false, false);
  }
  node.dispatchEvent(event);
}
function dispatchConstant(type, params) {
  return function() {
    return dispatchEvent2(this, type, params);
  };
}
function dispatchFunction(type, params) {
  return function() {
    return dispatchEvent2(this, type, params.apply(this, arguments));
  };
}
function dispatch_default(type, params) {
  return this.each((typeof params === "function" ? dispatchFunction : dispatchConstant)(type, params));
}

// ../../../../../node_modules/d3-selection/src/selection/iterator.js
function* iterator_default() {
  for (var groups = this._groups, j = 0, m = groups.length; j < m; ++j) {
    for (var group4 = groups[j], i2 = 0, n = group4.length, node; i2 < n; ++i2) {
      if (node = group4[i2]) yield node;
    }
  }
}

// ../../../../../node_modules/d3-selection/src/selection/index.js
var root = [null];
function Selection(groups, parents) {
  this._groups = groups;
  this._parents = parents;
}
function selection() {
  return new Selection([[document.documentElement]], root);
}
function selection_selection() {
  return this;
}
Selection.prototype = selection.prototype = {
  constructor: Selection,
  select: select_default,
  selectAll: selectAll_default,
  selectChild: selectChild_default,
  selectChildren: selectChildren_default,
  filter: filter_default,
  data: data_default,
  enter: enter_default,
  exit: exit_default,
  join: join_default,
  merge: merge_default,
  selection: selection_selection,
  order: order_default,
  sort: sort_default,
  call: call_default,
  nodes: nodes_default,
  node: node_default,
  size: size_default,
  empty: empty_default,
  each: each_default,
  attr: attr_default,
  style: style_default,
  property: property_default,
  classed: classed_default,
  text: text_default,
  html: html_default,
  raise: raise_default,
  lower: lower_default,
  append: append_default,
  insert: insert_default,
  remove: remove_default,
  clone: clone_default,
  datum: datum_default,
  on: on_default,
  dispatch: dispatch_default,
  [Symbol.iterator]: iterator_default
};
var selection_default = selection;

// ../../../../../node_modules/d3-selection/src/select.js
function select_default2(selector) {
  return typeof selector === "string" ? new Selection([[document.querySelector(selector)]], [document.documentElement]) : new Selection([[selector]], root);
}

// ../../../../../node_modules/d3-selection/src/sourceEvent.js
function sourceEvent_default(event) {
  let sourceEvent;
  while (sourceEvent = event.sourceEvent) event = sourceEvent;
  return event;
}

// ../../../../../node_modules/d3-selection/src/pointer.js
function pointer_default(event, node) {
  event = sourceEvent_default(event);
  if (node === void 0) node = event.currentTarget;
  if (node) {
    var svg = node.ownerSVGElement || node;
    if (svg.createSVGPoint) {
      var point = svg.createSVGPoint();
      point.x = event.clientX, point.y = event.clientY;
      point = point.matrixTransform(node.getScreenCTM().inverse());
      return [point.x, point.y];
    }
    if (node.getBoundingClientRect) {
      var rect = node.getBoundingClientRect();
      return [event.clientX - rect.left - node.clientLeft, event.clientY - rect.top - node.clientTop];
    }
  }
  return [event.pageX, event.pageY];
}

// ../../../../../node_modules/d3-dispatch/src/dispatch.js
var noop = { value: () => {
} };
function dispatch() {
  for (var i2 = 0, n = arguments.length, _ = {}, t; i2 < n; ++i2) {
    if (!(t = arguments[i2] + "") || t in _ || /[\s.]/.test(t)) throw new Error("illegal type: " + t);
    _[t] = [];
  }
  return new Dispatch(_);
}
function Dispatch(_) {
  this._ = _;
}
function parseTypenames2(typenames, types) {
  return typenames.trim().split(/^|\s+/).map(function(t) {
    var name15 = "", i2 = t.indexOf(".");
    if (i2 >= 0) name15 = t.slice(i2 + 1), t = t.slice(0, i2);
    if (t && !types.hasOwnProperty(t)) throw new Error("unknown type: " + t);
    return { type: t, name: name15 };
  });
}
Dispatch.prototype = dispatch.prototype = {
  constructor: Dispatch,
  on: function(typename, callback) {
    var _ = this._, T = parseTypenames2(typename + "", _), t, i2 = -1, n = T.length;
    if (arguments.length < 2) {
      while (++i2 < n) if ((t = (typename = T[i2]).type) && (t = get2(_[t], typename.name))) return t;
      return;
    }
    if (callback != null && typeof callback !== "function") throw new Error("invalid callback: " + callback);
    while (++i2 < n) {
      if (t = (typename = T[i2]).type) _[t] = set(_[t], typename.name, callback);
      else if (callback == null) for (t in _) _[t] = set(_[t], typename.name, null);
    }
    return this;
  },
  copy: function() {
    var copy2 = {}, _ = this._;
    for (var t in _) copy2[t] = _[t].slice();
    return new Dispatch(copy2);
  },
  call: function(type, that) {
    if ((n = arguments.length - 2) > 0) for (var args = new Array(n), i2 = 0, n, t; i2 < n; ++i2) args[i2] = arguments[i2 + 2];
    if (!this._.hasOwnProperty(type)) throw new Error("unknown type: " + type);
    for (t = this._[type], i2 = 0, n = t.length; i2 < n; ++i2) t[i2].value.apply(that, args);
  },
  apply: function(type, that, args) {
    if (!this._.hasOwnProperty(type)) throw new Error("unknown type: " + type);
    for (var t = this._[type], i2 = 0, n = t.length; i2 < n; ++i2) t[i2].value.apply(that, args);
  }
};
function get2(type, name15) {
  for (var i2 = 0, n = type.length, c; i2 < n; ++i2) {
    if ((c = type[i2]).name === name15) {
      return c.value;
    }
  }
}
function set(type, name15, callback) {
  for (var i2 = 0, n = type.length; i2 < n; ++i2) {
    if (type[i2].name === name15) {
      type[i2] = noop, type = type.slice(0, i2).concat(type.slice(i2 + 1));
      break;
    }
  }
  if (callback != null) type.push({ name: name15, value: callback });
  return type;
}
var dispatch_default2 = dispatch;

// ../../../../../node_modules/d3-drag/src/noevent.js
var nonpassive = { passive: false };
var nonpassivecapture = { capture: true, passive: false };
function nopropagation(event) {
  event.stopImmediatePropagation();
}
function noevent_default(event) {
  event.preventDefault();
  event.stopImmediatePropagation();
}

// ../../../../../node_modules/d3-drag/src/nodrag.js
function nodrag_default(view) {
  var root2 = view.document.documentElement, selection2 = select_default2(view).on("dragstart.drag", noevent_default, nonpassivecapture);
  if ("onselectstart" in root2) {
    selection2.on("selectstart.drag", noevent_default, nonpassivecapture);
  } else {
    root2.__noselect = root2.style.MozUserSelect;
    root2.style.MozUserSelect = "none";
  }
}
function yesdrag(view, noclick) {
  var root2 = view.document.documentElement, selection2 = select_default2(view).on("dragstart.drag", null);
  if (noclick) {
    selection2.on("click.drag", noevent_default, nonpassivecapture);
    setTimeout(function() {
      selection2.on("click.drag", null);
    }, 0);
  }
  if ("onselectstart" in root2) {
    selection2.on("selectstart.drag", null);
  } else {
    root2.style.MozUserSelect = root2.__noselect;
    delete root2.__noselect;
  }
}

// ../../../../../node_modules/d3-drag/src/constant.js
var constant_default2 = (x4) => () => x4;

// ../../../../../node_modules/d3-drag/src/event.js
function DragEvent(type, {
  sourceEvent,
  subject,
  target: target6,
  identifier,
  active,
  x: x4,
  y: y4,
  dx,
  dy,
  dispatch: dispatch2
}) {
  Object.defineProperties(this, {
    type: { value: type, enumerable: true, configurable: true },
    sourceEvent: { value: sourceEvent, enumerable: true, configurable: true },
    subject: { value: subject, enumerable: true, configurable: true },
    target: { value: target6, enumerable: true, configurable: true },
    identifier: { value: identifier, enumerable: true, configurable: true },
    active: { value: active, enumerable: true, configurable: true },
    x: { value: x4, enumerable: true, configurable: true },
    y: { value: y4, enumerable: true, configurable: true },
    dx: { value: dx, enumerable: true, configurable: true },
    dy: { value: dy, enumerable: true, configurable: true },
    _: { value: dispatch2 }
  });
}
DragEvent.prototype.on = function() {
  var value12 = this._.on.apply(this._, arguments);
  return value12 === this._ ? this : value12;
};

// ../../../../../node_modules/d3-drag/src/drag.js
function defaultFilter(event) {
  return !event.ctrlKey && !event.button;
}
function defaultContainer() {
  return this.parentNode;
}
function defaultSubject(event, d) {
  return d == null ? { x: event.x, y: event.y } : d;
}
function defaultTouchable() {
  return navigator.maxTouchPoints || "ontouchstart" in this;
}
function drag_default() {
  var filter4 = defaultFilter, container = defaultContainer, subject = defaultSubject, touchable = defaultTouchable, gestures = {}, listeners = dispatch_default2("start", "drag", "end"), active = 0, mousedownx, mousedowny, mousemoving, touchending, clickDistance2 = 0;
  function drag2(selection2) {
    selection2.on("mousedown.drag", mousedowned).filter(touchable).on("touchstart.drag", touchstarted).on("touchmove.drag", touchmoved, nonpassive).on("touchend.drag touchcancel.drag", touchended).style("touch-action", "none").style("-webkit-tap-highlight-color", "rgba(0,0,0,0)");
  }
  function mousedowned(event, d) {
    if (touchending || !filter4.call(this, event, d)) return;
    var gesture = beforestart(this, container.call(this, event, d), event, d, "mouse");
    if (!gesture) return;
    select_default2(event.view).on("mousemove.drag", mousemoved, nonpassivecapture).on("mouseup.drag", mouseupped, nonpassivecapture);
    nodrag_default(event.view);
    nopropagation(event);
    mousemoving = false;
    mousedownx = event.clientX;
    mousedowny = event.clientY;
    gesture("start", event);
  }
  function mousemoved(event) {
    noevent_default(event);
    if (!mousemoving) {
      var dx = event.clientX - mousedownx, dy = event.clientY - mousedowny;
      mousemoving = dx * dx + dy * dy > clickDistance2;
    }
    gestures.mouse("drag", event);
  }
  function mouseupped(event) {
    select_default2(event.view).on("mousemove.drag mouseup.drag", null);
    yesdrag(event.view, mousemoving);
    noevent_default(event);
    gestures.mouse("end", event);
  }
  function touchstarted(event, d) {
    if (!filter4.call(this, event, d)) return;
    var touches = event.changedTouches, c = container.call(this, event, d), n = touches.length, i2, gesture;
    for (i2 = 0; i2 < n; ++i2) {
      if (gesture = beforestart(this, c, event, d, touches[i2].identifier, touches[i2])) {
        nopropagation(event);
        gesture("start", event, touches[i2]);
      }
    }
  }
  function touchmoved(event) {
    var touches = event.changedTouches, n = touches.length, i2, gesture;
    for (i2 = 0; i2 < n; ++i2) {
      if (gesture = gestures[touches[i2].identifier]) {
        noevent_default(event);
        gesture("drag", event, touches[i2]);
      }
    }
  }
  function touchended(event) {
    var touches = event.changedTouches, n = touches.length, i2, gesture;
    if (touchending) clearTimeout(touchending);
    touchending = setTimeout(function() {
      touchending = null;
    }, 500);
    for (i2 = 0; i2 < n; ++i2) {
      if (gesture = gestures[touches[i2].identifier]) {
        nopropagation(event);
        gesture("end", event, touches[i2]);
      }
    }
  }
  function beforestart(that, container2, event, d, identifier, touch) {
    var dispatch2 = listeners.copy(), p2 = pointer_default(touch || event, container2), dx, dy, s;
    if ((s = subject.call(that, new DragEvent("beforestart", {
      sourceEvent: event,
      target: drag2,
      identifier,
      active,
      x: p2[0],
      y: p2[1],
      dx: 0,
      dy: 0,
      dispatch: dispatch2
    }), d)) == null) return;
    dx = s.x - p2[0] || 0;
    dy = s.y - p2[1] || 0;
    return function gesture(type, event2, touch2) {
      var p0 = p2, n;
      switch (type) {
        case "start":
          gestures[identifier] = gesture, n = active++;
          break;
        case "end":
          delete gestures[identifier], --active;
        // falls through
        case "drag":
          p2 = pointer_default(touch2 || event2, container2), n = active;
          break;
      }
      dispatch2.call(
        type,
        that,
        new DragEvent(type, {
          sourceEvent: event2,
          subject: s,
          target: drag2,
          identifier,
          active: n,
          x: p2[0] + dx,
          y: p2[1] + dy,
          dx: p2[0] - p0[0],
          dy: p2[1] - p0[1],
          dispatch: dispatch2
        }),
        d
      );
    };
  }
  drag2.filter = function(_) {
    return arguments.length ? (filter4 = typeof _ === "function" ? _ : constant_default2(!!_), drag2) : filter4;
  };
  drag2.container = function(_) {
    return arguments.length ? (container = typeof _ === "function" ? _ : constant_default2(_), drag2) : container;
  };
  drag2.subject = function(_) {
    return arguments.length ? (subject = typeof _ === "function" ? _ : constant_default2(_), drag2) : subject;
  };
  drag2.touchable = function(_) {
    return arguments.length ? (touchable = typeof _ === "function" ? _ : constant_default2(!!_), drag2) : touchable;
  };
  drag2.on = function() {
    var value12 = listeners.on.apply(listeners, arguments);
    return value12 === listeners ? drag2 : value12;
  };
  drag2.clickDistance = function(_) {
    return arguments.length ? (clickDistance2 = (_ = +_) * _, drag2) : Math.sqrt(clickDistance2);
  };
  return drag2;
}

// ../../../../../node_modules/d3-color/src/define.js
function define_default(constructor, factory, prototype) {
  constructor.prototype = factory.prototype = prototype;
  prototype.constructor = constructor;
}
function extend2(parent2, definition) {
  var prototype = Object.create(parent2.prototype);
  for (var key in definition) prototype[key] = definition[key];
  return prototype;
}

// ../../../../../node_modules/d3-color/src/color.js
function Color() {
}
var darker = 0.7;
var brighter = 1 / darker;
var reI = "\\s*([+-]?\\d+)\\s*";
var reN = "\\s*([+-]?(?:\\d*\\.)?\\d+(?:[eE][+-]?\\d+)?)\\s*";
var reP = "\\s*([+-]?(?:\\d*\\.)?\\d+(?:[eE][+-]?\\d+)?)%\\s*";
var reHex = /^#([0-9a-f]{3,8})$/;
var reRgbInteger = new RegExp(`^rgb\\(${reI},${reI},${reI}\\)$`);
var reRgbPercent = new RegExp(`^rgb\\(${reP},${reP},${reP}\\)$`);
var reRgbaInteger = new RegExp(`^rgba\\(${reI},${reI},${reI},${reN}\\)$`);
var reRgbaPercent = new RegExp(`^rgba\\(${reP},${reP},${reP},${reN}\\)$`);
var reHslPercent = new RegExp(`^hsl\\(${reN},${reP},${reP}\\)$`);
var reHslaPercent = new RegExp(`^hsla\\(${reN},${reP},${reP},${reN}\\)$`);
var named2 = {
  aliceblue: 15792383,
  antiquewhite: 16444375,
  aqua: 65535,
  aquamarine: 8388564,
  azure: 15794175,
  beige: 16119260,
  bisque: 16770244,
  black: 0,
  blanchedalmond: 16772045,
  blue: 255,
  blueviolet: 9055202,
  brown: 10824234,
  burlywood: 14596231,
  cadetblue: 6266528,
  chartreuse: 8388352,
  chocolate: 13789470,
  coral: 16744272,
  cornflowerblue: 6591981,
  cornsilk: 16775388,
  crimson: 14423100,
  cyan: 65535,
  darkblue: 139,
  darkcyan: 35723,
  darkgoldenrod: 12092939,
  darkgray: 11119017,
  darkgreen: 25600,
  darkgrey: 11119017,
  darkkhaki: 12433259,
  darkmagenta: 9109643,
  darkolivegreen: 5597999,
  darkorange: 16747520,
  darkorchid: 10040012,
  darkred: 9109504,
  darksalmon: 15308410,
  darkseagreen: 9419919,
  darkslateblue: 4734347,
  darkslategray: 3100495,
  darkslategrey: 3100495,
  darkturquoise: 52945,
  darkviolet: 9699539,
  deeppink: 16716947,
  deepskyblue: 49151,
  dimgray: 6908265,
  dimgrey: 6908265,
  dodgerblue: 2003199,
  firebrick: 11674146,
  floralwhite: 16775920,
  forestgreen: 2263842,
  fuchsia: 16711935,
  gainsboro: 14474460,
  ghostwhite: 16316671,
  gold: 16766720,
  goldenrod: 14329120,
  gray: 8421504,
  green: 32768,
  greenyellow: 11403055,
  grey: 8421504,
  honeydew: 15794160,
  hotpink: 16738740,
  indianred: 13458524,
  indigo: 4915330,
  ivory: 16777200,
  khaki: 15787660,
  lavender: 15132410,
  lavenderblush: 16773365,
  lawngreen: 8190976,
  lemonchiffon: 16775885,
  lightblue: 11393254,
  lightcoral: 15761536,
  lightcyan: 14745599,
  lightgoldenrodyellow: 16448210,
  lightgray: 13882323,
  lightgreen: 9498256,
  lightgrey: 13882323,
  lightpink: 16758465,
  lightsalmon: 16752762,
  lightseagreen: 2142890,
  lightskyblue: 8900346,
  lightslategray: 7833753,
  lightslategrey: 7833753,
  lightsteelblue: 11584734,
  lightyellow: 16777184,
  lime: 65280,
  limegreen: 3329330,
  linen: 16445670,
  magenta: 16711935,
  maroon: 8388608,
  mediumaquamarine: 6737322,
  mediumblue: 205,
  mediumorchid: 12211667,
  mediumpurple: 9662683,
  mediumseagreen: 3978097,
  mediumslateblue: 8087790,
  mediumspringgreen: 64154,
  mediumturquoise: 4772300,
  mediumvioletred: 13047173,
  midnightblue: 1644912,
  mintcream: 16121850,
  mistyrose: 16770273,
  moccasin: 16770229,
  navajowhite: 16768685,
  navy: 128,
  oldlace: 16643558,
  olive: 8421376,
  olivedrab: 7048739,
  orange: 16753920,
  orangered: 16729344,
  orchid: 14315734,
  palegoldenrod: 15657130,
  palegreen: 10025880,
  paleturquoise: 11529966,
  palevioletred: 14381203,
  papayawhip: 16773077,
  peachpuff: 16767673,
  peru: 13468991,
  pink: 16761035,
  plum: 14524637,
  powderblue: 11591910,
  purple: 8388736,
  rebeccapurple: 6697881,
  red: 16711680,
  rosybrown: 12357519,
  royalblue: 4286945,
  saddlebrown: 9127187,
  salmon: 16416882,
  sandybrown: 16032864,
  seagreen: 3050327,
  seashell: 16774638,
  sienna: 10506797,
  silver: 12632256,
  skyblue: 8900331,
  slateblue: 6970061,
  slategray: 7372944,
  slategrey: 7372944,
  snow: 16775930,
  springgreen: 65407,
  steelblue: 4620980,
  tan: 13808780,
  teal: 32896,
  thistle: 14204888,
  tomato: 16737095,
  turquoise: 4251856,
  violet: 15631086,
  wheat: 16113331,
  white: 16777215,
  whitesmoke: 16119285,
  yellow: 16776960,
  yellowgreen: 10145074
};
define_default(Color, color, {
  copy(channels) {
    return Object.assign(new this.constructor(), this, channels);
  },
  displayable() {
    return this.rgb().displayable();
  },
  hex: color_formatHex,
  // Deprecated! Use color.formatHex.
  formatHex: color_formatHex,
  formatHex8: color_formatHex8,
  formatHsl: color_formatHsl,
  formatRgb: color_formatRgb,
  toString: color_formatRgb
});
function color_formatHex() {
  return this.rgb().formatHex();
}
function color_formatHex8() {
  return this.rgb().formatHex8();
}
function color_formatHsl() {
  return hslConvert(this).formatHsl();
}
function color_formatRgb() {
  return this.rgb().formatRgb();
}
function color(format) {
  var m, l;
  format = (format + "").trim().toLowerCase();
  return (m = reHex.exec(format)) ? (l = m[1].length, m = parseInt(m[1], 16), l === 6 ? rgbn(m) : l === 3 ? new Rgb(m >> 8 & 15 | m >> 4 & 240, m >> 4 & 15 | m & 240, (m & 15) << 4 | m & 15, 1) : l === 8 ? rgba(m >> 24 & 255, m >> 16 & 255, m >> 8 & 255, (m & 255) / 255) : l === 4 ? rgba(m >> 12 & 15 | m >> 8 & 240, m >> 8 & 15 | m >> 4 & 240, m >> 4 & 15 | m & 240, ((m & 15) << 4 | m & 15) / 255) : null) : (m = reRgbInteger.exec(format)) ? new Rgb(m[1], m[2], m[3], 1) : (m = reRgbPercent.exec(format)) ? new Rgb(m[1] * 255 / 100, m[2] * 255 / 100, m[3] * 255 / 100, 1) : (m = reRgbaInteger.exec(format)) ? rgba(m[1], m[2], m[3], m[4]) : (m = reRgbaPercent.exec(format)) ? rgba(m[1] * 255 / 100, m[2] * 255 / 100, m[3] * 255 / 100, m[4]) : (m = reHslPercent.exec(format)) ? hsla(m[1], m[2] / 100, m[3] / 100, 1) : (m = reHslaPercent.exec(format)) ? hsla(m[1], m[2] / 100, m[3] / 100, m[4]) : named2.hasOwnProperty(format) ? rgbn(named2[format]) : format === "transparent" ? new Rgb(NaN, NaN, NaN, 0) : null;
}
function rgbn(n) {
  return new Rgb(n >> 16 & 255, n >> 8 & 255, n & 255, 1);
}
function rgba(r, g, b10, a2) {
  if (a2 <= 0) r = g = b10 = NaN;
  return new Rgb(r, g, b10, a2);
}
function rgbConvert(o) {
  if (!(o instanceof Color)) o = color(o);
  if (!o) return new Rgb();
  o = o.rgb();
  return new Rgb(o.r, o.g, o.b, o.opacity);
}
function rgb2(r, g, b10, opacity) {
  return arguments.length === 1 ? rgbConvert(r) : new Rgb(r, g, b10, opacity == null ? 1 : opacity);
}
function Rgb(r, g, b10, opacity) {
  this.r = +r;
  this.g = +g;
  this.b = +b10;
  this.opacity = +opacity;
}
define_default(Rgb, rgb2, extend2(Color, {
  brighter(k) {
    k = k == null ? brighter : Math.pow(brighter, k);
    return new Rgb(this.r * k, this.g * k, this.b * k, this.opacity);
  },
  darker(k) {
    k = k == null ? darker : Math.pow(darker, k);
    return new Rgb(this.r * k, this.g * k, this.b * k, this.opacity);
  },
  rgb() {
    return this;
  },
  clamp() {
    return new Rgb(clampi(this.r), clampi(this.g), clampi(this.b), clampa(this.opacity));
  },
  displayable() {
    return -0.5 <= this.r && this.r < 255.5 && (-0.5 <= this.g && this.g < 255.5) && (-0.5 <= this.b && this.b < 255.5) && (0 <= this.opacity && this.opacity <= 1);
  },
  hex: rgb_formatHex,
  // Deprecated! Use color.formatHex.
  formatHex: rgb_formatHex,
  formatHex8: rgb_formatHex8,
  formatRgb: rgb_formatRgb,
  toString: rgb_formatRgb
}));
function rgb_formatHex() {
  return `#${hex(this.r)}${hex(this.g)}${hex(this.b)}`;
}
function rgb_formatHex8() {
  return `#${hex(this.r)}${hex(this.g)}${hex(this.b)}${hex((isNaN(this.opacity) ? 1 : this.opacity) * 255)}`;
}
function rgb_formatRgb() {
  const a2 = clampa(this.opacity);
  return `${a2 === 1 ? "rgb(" : "rgba("}${clampi(this.r)}, ${clampi(this.g)}, ${clampi(this.b)}${a2 === 1 ? ")" : `, ${a2})`}`;
}
function clampa(opacity) {
  return isNaN(opacity) ? 1 : Math.max(0, Math.min(1, opacity));
}
function clampi(value12) {
  return Math.max(0, Math.min(255, Math.round(value12) || 0));
}
function hex(value12) {
  value12 = clampi(value12);
  return (value12 < 16 ? "0" : "") + value12.toString(16);
}
function hsla(h, s, l, a2) {
  if (a2 <= 0) h = s = l = NaN;
  else if (l <= 0 || l >= 1) h = s = NaN;
  else if (s <= 0) h = NaN;
  return new Hsl(h, s, l, a2);
}
function hslConvert(o) {
  if (o instanceof Hsl) return new Hsl(o.h, o.s, o.l, o.opacity);
  if (!(o instanceof Color)) o = color(o);
  if (!o) return new Hsl();
  if (o instanceof Hsl) return o;
  o = o.rgb();
  var r = o.r / 255, g = o.g / 255, b10 = o.b / 255, min5 = Math.min(r, g, b10), max7 = Math.max(r, g, b10), h = NaN, s = max7 - min5, l = (max7 + min5) / 2;
  if (s) {
    if (r === max7) h = (g - b10) / s + (g < b10) * 6;
    else if (g === max7) h = (b10 - r) / s + 2;
    else h = (r - g) / s + 4;
    s /= l < 0.5 ? max7 + min5 : 2 - max7 - min5;
    h *= 60;
  } else {
    s = l > 0 && l < 1 ? 0 : h;
  }
  return new Hsl(h, s, l, o.opacity);
}
function hsl2(h, s, l, opacity) {
  return arguments.length === 1 ? hslConvert(h) : new Hsl(h, s, l, opacity == null ? 1 : opacity);
}
function Hsl(h, s, l, opacity) {
  this.h = +h;
  this.s = +s;
  this.l = +l;
  this.opacity = +opacity;
}
define_default(Hsl, hsl2, extend2(Color, {
  brighter(k) {
    k = k == null ? brighter : Math.pow(brighter, k);
    return new Hsl(this.h, this.s, this.l * k, this.opacity);
  },
  darker(k) {
    k = k == null ? darker : Math.pow(darker, k);
    return new Hsl(this.h, this.s, this.l * k, this.opacity);
  },
  rgb() {
    var h = this.h % 360 + (this.h < 0) * 360, s = isNaN(h) || isNaN(this.s) ? 0 : this.s, l = this.l, m2 = l + (l < 0.5 ? l : 1 - l) * s, m1 = 2 * l - m2;
    return new Rgb(
      hsl2rgb(h >= 240 ? h - 240 : h + 120, m1, m2),
      hsl2rgb(h, m1, m2),
      hsl2rgb(h < 120 ? h + 240 : h - 120, m1, m2),
      this.opacity
    );
  },
  clamp() {
    return new Hsl(clamph(this.h), clampt(this.s), clampt(this.l), clampa(this.opacity));
  },
  displayable() {
    return (0 <= this.s && this.s <= 1 || isNaN(this.s)) && (0 <= this.l && this.l <= 1) && (0 <= this.opacity && this.opacity <= 1);
  },
  formatHsl() {
    const a2 = clampa(this.opacity);
    return `${a2 === 1 ? "hsl(" : "hsla("}${clamph(this.h)}, ${clampt(this.s) * 100}%, ${clampt(this.l) * 100}%${a2 === 1 ? ")" : `, ${a2})`}`;
  }
}));
function clamph(value12) {
  value12 = (value12 || 0) % 360;
  return value12 < 0 ? value12 + 360 : value12;
}
function clampt(value12) {
  return Math.max(0, Math.min(1, value12 || 0));
}
function hsl2rgb(h, m1, m2) {
  return (h < 60 ? m1 + (m2 - m1) * h / 60 : h < 180 ? m2 : h < 240 ? m1 + (m2 - m1) * (240 - h) / 60 : m1) * 255;
}

// ../../../../../node_modules/d3-interpolate/src/basis.js
function basis(t1, v0, v1, v2, v3) {
  var t2 = t1 * t1, t3 = t2 * t1;
  return ((1 - 3 * t1 + 3 * t2 - t3) * v0 + (4 - 6 * t2 + 3 * t3) * v1 + (1 + 3 * t1 + 3 * t2 - 3 * t3) * v2 + t3 * v3) / 6;
}
function basis_default(values2) {
  var n = values2.length - 1;
  return function(t) {
    var i2 = t <= 0 ? t = 0 : t >= 1 ? (t = 1, n - 1) : Math.floor(t * n), v1 = values2[i2], v2 = values2[i2 + 1], v0 = i2 > 0 ? values2[i2 - 1] : 2 * v1 - v2, v3 = i2 < n - 1 ? values2[i2 + 2] : 2 * v2 - v1;
    return basis((t - i2 / n) * n, v0, v1, v2, v3);
  };
}

// ../../../../../node_modules/d3-interpolate/src/basisClosed.js
function basisClosed_default(values2) {
  var n = values2.length;
  return function(t) {
    var i2 = Math.floor(((t %= 1) < 0 ? ++t : t) * n), v0 = values2[(i2 + n - 1) % n], v1 = values2[i2 % n], v2 = values2[(i2 + 1) % n], v3 = values2[(i2 + 2) % n];
    return basis((t - i2 / n) * n, v0, v1, v2, v3);
  };
}

// ../../../../../node_modules/d3-interpolate/src/constant.js
var constant_default3 = (x4) => () => x4;

// ../../../../../node_modules/d3-interpolate/src/color.js
function linear(a2, d) {
  return function(t) {
    return a2 + t * d;
  };
}
function exponential(a2, b10, y4) {
  return a2 = Math.pow(a2, y4), b10 = Math.pow(b10, y4) - a2, y4 = 1 / y4, function(t) {
    return Math.pow(a2 + t * b10, y4);
  };
}
function gamma(y4) {
  return (y4 = +y4) === 1 ? nogamma : function(a2, b10) {
    return b10 - a2 ? exponential(a2, b10, y4) : constant_default3(isNaN(a2) ? b10 : a2);
  };
}
function nogamma(a2, b10) {
  var d = b10 - a2;
  return d ? linear(a2, d) : constant_default3(isNaN(a2) ? b10 : a2);
}

// ../../../../../node_modules/d3-interpolate/src/rgb.js
var rgb_default = (function rgbGamma(y4) {
  var color2 = gamma(y4);
  function rgb3(start3, end) {
    var r = color2((start3 = rgb2(start3)).r, (end = rgb2(end)).r), g = color2(start3.g, end.g), b10 = color2(start3.b, end.b), opacity = nogamma(start3.opacity, end.opacity);
    return function(t) {
      start3.r = r(t);
      start3.g = g(t);
      start3.b = b10(t);
      start3.opacity = opacity(t);
      return start3 + "";
    };
  }
  rgb3.gamma = rgbGamma;
  return rgb3;
})(1);
function rgbSpline(spline) {
  return function(colors) {
    var n = colors.length, r = new Array(n), g = new Array(n), b10 = new Array(n), i2, color2;
    for (i2 = 0; i2 < n; ++i2) {
      color2 = rgb2(colors[i2]);
      r[i2] = color2.r || 0;
      g[i2] = color2.g || 0;
      b10[i2] = color2.b || 0;
    }
    r = spline(r);
    g = spline(g);
    b10 = spline(b10);
    color2.opacity = 1;
    return function(t) {
      color2.r = r(t);
      color2.g = g(t);
      color2.b = b10(t);
      return color2 + "";
    };
  };
}
var rgbBasis = rgbSpline(basis_default);
var rgbBasisClosed = rgbSpline(basisClosed_default);

// ../../../../../node_modules/d3-interpolate/src/number.js
function number_default(a2, b10) {
  return a2 = +a2, b10 = +b10, function(t) {
    return a2 * (1 - t) + b10 * t;
  };
}

// ../../../../../node_modules/d3-interpolate/src/string.js
var reA = /[-+]?(?:\d+\.?\d*|\.?\d+)(?:[eE][-+]?\d+)?/g;
var reB = new RegExp(reA.source, "g");
function zero2(b10) {
  return function() {
    return b10;
  };
}
function one2(b10) {
  return function(t) {
    return b10(t) + "";
  };
}
function string_default(a2, b10) {
  var bi = reA.lastIndex = reB.lastIndex = 0, am, bm, bs, i2 = -1, s = [], q2 = [];
  a2 = a2 + "", b10 = b10 + "";
  while ((am = reA.exec(a2)) && (bm = reB.exec(b10))) {
    if ((bs = bm.index) > bi) {
      bs = b10.slice(bi, bs);
      if (s[i2]) s[i2] += bs;
      else s[++i2] = bs;
    }
    if ((am = am[0]) === (bm = bm[0])) {
      if (s[i2]) s[i2] += bm;
      else s[++i2] = bm;
    } else {
      s[++i2] = null;
      q2.push({ i: i2, x: number_default(am, bm) });
    }
    bi = reB.lastIndex;
  }
  if (bi < b10.length) {
    bs = b10.slice(bi);
    if (s[i2]) s[i2] += bs;
    else s[++i2] = bs;
  }
  return s.length < 2 ? q2[0] ? one2(q2[0].x) : zero2(b10) : (b10 = q2.length, function(t) {
    for (var i3 = 0, o; i3 < b10; ++i3) s[(o = q2[i3]).i] = o.x(t);
    return s.join("");
  });
}

// ../../../../../node_modules/d3-interpolate/src/transform/decompose.js
var degrees = 180 / Math.PI;
var identity9 = {
  translateX: 0,
  translateY: 0,
  rotate: 0,
  skewX: 0,
  scaleX: 1,
  scaleY: 1
};
function decompose_default(a2, b10, c, d, e, f) {
  var scaleX, scaleY, skewX;
  if (scaleX = Math.sqrt(a2 * a2 + b10 * b10)) a2 /= scaleX, b10 /= scaleX;
  if (skewX = a2 * c + b10 * d) c -= a2 * skewX, d -= b10 * skewX;
  if (scaleY = Math.sqrt(c * c + d * d)) c /= scaleY, d /= scaleY, skewX /= scaleY;
  if (a2 * d < b10 * c) a2 = -a2, b10 = -b10, skewX = -skewX, scaleX = -scaleX;
  return {
    translateX: e,
    translateY: f,
    rotate: Math.atan2(b10, a2) * degrees,
    skewX: Math.atan(skewX) * degrees,
    scaleX,
    scaleY
  };
}

// ../../../../../node_modules/d3-interpolate/src/transform/parse.js
var svgNode;
function parseCss(value12) {
  const m = new (typeof DOMMatrix === "function" ? DOMMatrix : WebKitCSSMatrix)(value12 + "");
  return m.isIdentity ? identity9 : decompose_default(m.a, m.b, m.c, m.d, m.e, m.f);
}
function parseSvg(value12) {
  if (value12 == null) return identity9;
  if (!svgNode) svgNode = document.createElementNS("http://www.w3.org/2000/svg", "g");
  svgNode.setAttribute("transform", value12);
  if (!(value12 = svgNode.transform.baseVal.consolidate())) return identity9;
  value12 = value12.matrix;
  return decompose_default(value12.a, value12.b, value12.c, value12.d, value12.e, value12.f);
}

// ../../../../../node_modules/d3-interpolate/src/transform/index.js
function interpolateTransform(parse7, pxComma, pxParen, degParen) {
  function pop3(s) {
    return s.length ? s.pop() + " " : "";
  }
  function translate(xa, ya, xb, yb, s, q2) {
    if (xa !== xb || ya !== yb) {
      var i2 = s.push("translate(", null, pxComma, null, pxParen);
      q2.push({ i: i2 - 4, x: number_default(xa, xb) }, { i: i2 - 2, x: number_default(ya, yb) });
    } else if (xb || yb) {
      s.push("translate(" + xb + pxComma + yb + pxParen);
    }
  }
  function rotate(a2, b10, s, q2) {
    if (a2 !== b10) {
      if (a2 - b10 > 180) b10 += 360;
      else if (b10 - a2 > 180) a2 += 360;
      q2.push({ i: s.push(pop3(s) + "rotate(", null, degParen) - 2, x: number_default(a2, b10) });
    } else if (b10) {
      s.push(pop3(s) + "rotate(" + b10 + degParen);
    }
  }
  function skewX(a2, b10, s, q2) {
    if (a2 !== b10) {
      q2.push({ i: s.push(pop3(s) + "skewX(", null, degParen) - 2, x: number_default(a2, b10) });
    } else if (b10) {
      s.push(pop3(s) + "skewX(" + b10 + degParen);
    }
  }
  function scale(xa, ya, xb, yb, s, q2) {
    if (xa !== xb || ya !== yb) {
      var i2 = s.push(pop3(s) + "scale(", null, ",", null, ")");
      q2.push({ i: i2 - 4, x: number_default(xa, xb) }, { i: i2 - 2, x: number_default(ya, yb) });
    } else if (xb !== 1 || yb !== 1) {
      s.push(pop3(s) + "scale(" + xb + "," + yb + ")");
    }
  }
  return function(a2, b10) {
    var s = [], q2 = [];
    a2 = parse7(a2), b10 = parse7(b10);
    translate(a2.translateX, a2.translateY, b10.translateX, b10.translateY, s, q2);
    rotate(a2.rotate, b10.rotate, s, q2);
    skewX(a2.skewX, b10.skewX, s, q2);
    scale(a2.scaleX, a2.scaleY, b10.scaleX, b10.scaleY, s, q2);
    a2 = b10 = null;
    return function(t) {
      var i2 = -1, n = q2.length, o;
      while (++i2 < n) s[(o = q2[i2]).i] = o.x(t);
      return s.join("");
    };
  };
}
var interpolateTransformCss = interpolateTransform(parseCss, "px, ", "px)", "deg)");
var interpolateTransformSvg = interpolateTransform(parseSvg, ", ", ")", ")");

// ../../../../../node_modules/d3-interpolate/src/zoom.js
var epsilon2 = 1e-12;
function cosh(x4) {
  return ((x4 = Math.exp(x4)) + 1 / x4) / 2;
}
function sinh(x4) {
  return ((x4 = Math.exp(x4)) - 1 / x4) / 2;
}
function tanh(x4) {
  return ((x4 = Math.exp(2 * x4)) - 1) / (x4 + 1);
}
var zoom_default = (function zoomRho(rho, rho2, rho4) {
  function zoom(p0, p1) {
    var ux0 = p0[0], uy0 = p0[1], w0 = p0[2], ux1 = p1[0], uy1 = p1[1], w1 = p1[2], dx = ux1 - ux0, dy = uy1 - uy0, d2 = dx * dx + dy * dy, i2, S;
    if (d2 < epsilon2) {
      S = Math.log(w1 / w0) / rho;
      i2 = function(t) {
        return [
          ux0 + t * dx,
          uy0 + t * dy,
          w0 * Math.exp(rho * t * S)
        ];
      };
    } else {
      var d1 = Math.sqrt(d2), b02 = (w1 * w1 - w0 * w0 + rho4 * d2) / (2 * w0 * rho2 * d1), b12 = (w1 * w1 - w0 * w0 - rho4 * d2) / (2 * w1 * rho2 * d1), r0 = Math.log(Math.sqrt(b02 * b02 + 1) - b02), r1 = Math.log(Math.sqrt(b12 * b12 + 1) - b12);
      S = (r1 - r0) / rho;
      i2 = function(t) {
        var s = t * S, coshr0 = cosh(r0), u2 = w0 / (rho2 * d1) * (coshr0 * tanh(rho * s + r0) - sinh(r0));
        return [
          ux0 + u2 * dx,
          uy0 + u2 * dy,
          w0 * coshr0 / cosh(rho * s + r0)
        ];
      };
    }
    i2.duration = S * 1e3 * rho / Math.SQRT2;
    return i2;
  }
  zoom.rho = function(_) {
    var _1 = Math.max(1e-3, +_), _2 = _1 * _1, _4 = _2 * _2;
    return zoomRho(_1, _2, _4);
  };
  return zoom;
})(Math.SQRT2, 2, 4);

// ../../../../../node_modules/d3-timer/src/timer.js
var frame = 0;
var timeout = 0;
var interval = 0;
var pokeDelay = 1e3;
var taskHead;
var taskTail;
var clockLast = 0;
var clockNow = 0;
var clockSkew = 0;
var clock = typeof performance === "object" && performance.now ? performance : Date;
var setFrame = typeof window === "object" && window.requestAnimationFrame ? window.requestAnimationFrame.bind(window) : function(f) {
  setTimeout(f, 17);
};
function now() {
  return clockNow || (setFrame(clearNow), clockNow = clock.now() + clockSkew);
}
function clearNow() {
  clockNow = 0;
}
function Timer() {
  this._call = this._time = this._next = null;
}
Timer.prototype = timer.prototype = {
  constructor: Timer,
  restart: function(callback, delay, time3) {
    if (typeof callback !== "function") throw new TypeError("callback is not a function");
    time3 = (time3 == null ? now() : +time3) + (delay == null ? 0 : +delay);
    if (!this._next && taskTail !== this) {
      if (taskTail) taskTail._next = this;
      else taskHead = this;
      taskTail = this;
    }
    this._call = callback;
    this._time = time3;
    sleep();
  },
  stop: function() {
    if (this._call) {
      this._call = null;
      this._time = Infinity;
      sleep();
    }
  }
};
function timer(callback, delay, time3) {
  var t = new Timer();
  t.restart(callback, delay, time3);
  return t;
}
function timerFlush() {
  now();
  ++frame;
  var t = taskHead, e;
  while (t) {
    if ((e = clockNow - t._time) >= 0) t._call.call(void 0, e);
    t = t._next;
  }
  --frame;
}
function wake() {
  clockNow = (clockLast = clock.now()) + clockSkew;
  frame = timeout = 0;
  try {
    timerFlush();
  } finally {
    frame = 0;
    nap();
    clockNow = 0;
  }
}
function poke3() {
  var now2 = clock.now(), delay = now2 - clockLast;
  if (delay > pokeDelay) clockSkew -= delay, clockLast = now2;
}
function nap() {
  var t0, t1 = taskHead, t2, time3 = Infinity;
  while (t1) {
    if (t1._call) {
      if (time3 > t1._time) time3 = t1._time;
      t0 = t1, t1 = t1._next;
    } else {
      t2 = t1._next, t1._next = null;
      t1 = t0 ? t0._next = t2 : taskHead = t2;
    }
  }
  taskTail = t0;
  sleep(time3);
}
function sleep(time3) {
  if (frame) return;
  if (timeout) timeout = clearTimeout(timeout);
  var delay = time3 - clockNow;
  if (delay > 24) {
    if (time3 < Infinity) timeout = setTimeout(wake, time3 - clock.now() - clockSkew);
    if (interval) interval = clearInterval(interval);
  } else {
    if (!interval) clockLast = clock.now(), interval = setInterval(poke3, pokeDelay);
    frame = 1, setFrame(wake);
  }
}

// ../../../../../node_modules/d3-timer/src/timeout.js
function timeout_default(callback, delay, time3) {
  var t = new Timer();
  delay = delay == null ? 0 : +delay;
  t.restart((elapsed) => {
    t.stop();
    callback(elapsed + delay);
  }, delay, time3);
  return t;
}

// ../../../../../node_modules/d3-transition/src/transition/schedule.js
var emptyOn = dispatch_default2("start", "end", "cancel", "interrupt");
var emptyTween = [];
var CREATED = 0;
var SCHEDULED = 1;
var STARTING = 2;
var STARTED = 3;
var RUNNING = 4;
var ENDING = 5;
var ENDED = 6;
function schedule_default(node, name15, id4, index6, group4, timing) {
  var schedules = node.__transition;
  if (!schedules) node.__transition = {};
  else if (id4 in schedules) return;
  create4(node, id4, {
    name: name15,
    index: index6,
    // For context during callback.
    group: group4,
    // For context during callback.
    on: emptyOn,
    tween: emptyTween,
    time: timing.time,
    delay: timing.delay,
    duration: timing.duration,
    ease: timing.ease,
    timer: null,
    state: CREATED
  });
}
function init3(node, id4) {
  var schedule = get3(node, id4);
  if (schedule.state > CREATED) throw new Error("too late; already scheduled");
  return schedule;
}
function set2(node, id4) {
  var schedule = get3(node, id4);
  if (schedule.state > STARTED) throw new Error("too late; already running");
  return schedule;
}
function get3(node, id4) {
  var schedule = node.__transition;
  if (!schedule || !(schedule = schedule[id4])) throw new Error("transition not found");
  return schedule;
}
function create4(node, id4, self) {
  var schedules = node.__transition, tween;
  schedules[id4] = self;
  self.timer = timer(schedule, 0, self.time);
  function schedule(elapsed) {
    self.state = SCHEDULED;
    self.timer.restart(start3, self.delay, self.time);
    if (self.delay <= elapsed) start3(elapsed - self.delay);
  }
  function start3(elapsed) {
    var i2, j, n, o;
    if (self.state !== SCHEDULED) return stop();
    for (i2 in schedules) {
      o = schedules[i2];
      if (o.name !== self.name) continue;
      if (o.state === STARTED) return timeout_default(start3);
      if (o.state === RUNNING) {
        o.state = ENDED;
        o.timer.stop();
        o.on.call("interrupt", node, node.__data__, o.index, o.group);
        delete schedules[i2];
      } else if (+i2 < id4) {
        o.state = ENDED;
        o.timer.stop();
        o.on.call("cancel", node, node.__data__, o.index, o.group);
        delete schedules[i2];
      }
    }
    timeout_default(function() {
      if (self.state === STARTED) {
        self.state = RUNNING;
        self.timer.restart(tick, self.delay, self.time);
        tick(elapsed);
      }
    });
    self.state = STARTING;
    self.on.call("start", node, node.__data__, self.index, self.group);
    if (self.state !== STARTING) return;
    self.state = STARTED;
    tween = new Array(n = self.tween.length);
    for (i2 = 0, j = -1; i2 < n; ++i2) {
      if (o = self.tween[i2].value.call(node, node.__data__, self.index, self.group)) {
        tween[++j] = o;
      }
    }
    tween.length = j + 1;
  }
  function tick(elapsed) {
    var t = elapsed < self.duration ? self.ease.call(null, elapsed / self.duration) : (self.timer.restart(stop), self.state = ENDING, 1), i2 = -1, n = tween.length;
    while (++i2 < n) {
      tween[i2].call(node, t);
    }
    if (self.state === ENDING) {
      self.on.call("end", node, node.__data__, self.index, self.group);
      stop();
    }
  }
  function stop() {
    self.state = ENDED;
    self.timer.stop();
    delete schedules[id4];
    for (var i2 in schedules) return;
    delete node.__transition;
  }
}

// ../../../../../node_modules/d3-transition/src/interrupt.js
function interrupt_default(node, name15) {
  var schedules = node.__transition, schedule, active, empty8 = true, i2;
  if (!schedules) return;
  name15 = name15 == null ? null : name15 + "";
  for (i2 in schedules) {
    if ((schedule = schedules[i2]).name !== name15) {
      empty8 = false;
      continue;
    }
    active = schedule.state > STARTING && schedule.state < ENDING;
    schedule.state = ENDED;
    schedule.timer.stop();
    schedule.on.call(active ? "interrupt" : "cancel", node, node.__data__, schedule.index, schedule.group);
    delete schedules[i2];
  }
  if (empty8) delete node.__transition;
}

// ../../../../../node_modules/d3-transition/src/selection/interrupt.js
function interrupt_default2(name15) {
  return this.each(function() {
    interrupt_default(this, name15);
  });
}

// ../../../../../node_modules/d3-transition/src/transition/tween.js
function tweenRemove(id4, name15) {
  var tween0, tween1;
  return function() {
    var schedule = set2(this, id4), tween = schedule.tween;
    if (tween !== tween0) {
      tween1 = tween0 = tween;
      for (var i2 = 0, n = tween1.length; i2 < n; ++i2) {
        if (tween1[i2].name === name15) {
          tween1 = tween1.slice();
          tween1.splice(i2, 1);
          break;
        }
      }
    }
    schedule.tween = tween1;
  };
}
function tweenFunction(id4, name15, value12) {
  var tween0, tween1;
  if (typeof value12 !== "function") throw new Error();
  return function() {
    var schedule = set2(this, id4), tween = schedule.tween;
    if (tween !== tween0) {
      tween1 = (tween0 = tween).slice();
      for (var t = { name: name15, value: value12 }, i2 = 0, n = tween1.length; i2 < n; ++i2) {
        if (tween1[i2].name === name15) {
          tween1[i2] = t;
          break;
        }
      }
      if (i2 === n) tween1.push(t);
    }
    schedule.tween = tween1;
  };
}
function tween_default(name15, value12) {
  var id4 = this._id;
  name15 += "";
  if (arguments.length < 2) {
    var tween = get3(this.node(), id4).tween;
    for (var i2 = 0, n = tween.length, t; i2 < n; ++i2) {
      if ((t = tween[i2]).name === name15) {
        return t.value;
      }
    }
    return null;
  }
  return this.each((value12 == null ? tweenRemove : tweenFunction)(id4, name15, value12));
}
function tweenValue(transition2, name15, value12) {
  var id4 = transition2._id;
  transition2.each(function() {
    var schedule = set2(this, id4);
    (schedule.value || (schedule.value = {}))[name15] = value12.apply(this, arguments);
  });
  return function(node) {
    return get3(node, id4).value[name15];
  };
}

// ../../../../../node_modules/d3-transition/src/transition/interpolate.js
function interpolate_default(a2, b10) {
  var c;
  return (typeof b10 === "number" ? number_default : b10 instanceof color ? rgb_default : (c = color(b10)) ? (b10 = c, rgb_default) : string_default)(a2, b10);
}

// ../../../../../node_modules/d3-transition/src/transition/attr.js
function attrRemove2(name15) {
  return function() {
    this.removeAttribute(name15);
  };
}
function attrRemoveNS2(fullname) {
  return function() {
    this.removeAttributeNS(fullname.space, fullname.local);
  };
}
function attrConstant2(name15, interpolate, value1) {
  var string00, string1 = value1 + "", interpolate0;
  return function() {
    var string0 = this.getAttribute(name15);
    return string0 === string1 ? null : string0 === string00 ? interpolate0 : interpolate0 = interpolate(string00 = string0, value1);
  };
}
function attrConstantNS2(fullname, interpolate, value1) {
  var string00, string1 = value1 + "", interpolate0;
  return function() {
    var string0 = this.getAttributeNS(fullname.space, fullname.local);
    return string0 === string1 ? null : string0 === string00 ? interpolate0 : interpolate0 = interpolate(string00 = string0, value1);
  };
}
function attrFunction2(name15, interpolate, value12) {
  var string00, string10, interpolate0;
  return function() {
    var string0, value1 = value12(this), string1;
    if (value1 == null) return void this.removeAttribute(name15);
    string0 = this.getAttribute(name15);
    string1 = value1 + "";
    return string0 === string1 ? null : string0 === string00 && string1 === string10 ? interpolate0 : (string10 = string1, interpolate0 = interpolate(string00 = string0, value1));
  };
}
function attrFunctionNS2(fullname, interpolate, value12) {
  var string00, string10, interpolate0;
  return function() {
    var string0, value1 = value12(this), string1;
    if (value1 == null) return void this.removeAttributeNS(fullname.space, fullname.local);
    string0 = this.getAttributeNS(fullname.space, fullname.local);
    string1 = value1 + "";
    return string0 === string1 ? null : string0 === string00 && string1 === string10 ? interpolate0 : (string10 = string1, interpolate0 = interpolate(string00 = string0, value1));
  };
}
function attr_default2(name15, value12) {
  var fullname = namespace_default(name15), i2 = fullname === "transform" ? interpolateTransformSvg : interpolate_default;
  return this.attrTween(name15, typeof value12 === "function" ? (fullname.local ? attrFunctionNS2 : attrFunction2)(fullname, i2, tweenValue(this, "attr." + name15, value12)) : value12 == null ? (fullname.local ? attrRemoveNS2 : attrRemove2)(fullname) : (fullname.local ? attrConstantNS2 : attrConstant2)(fullname, i2, value12));
}

// ../../../../../node_modules/d3-transition/src/transition/attrTween.js
function attrInterpolate(name15, i2) {
  return function(t) {
    this.setAttribute(name15, i2.call(this, t));
  };
}
function attrInterpolateNS(fullname, i2) {
  return function(t) {
    this.setAttributeNS(fullname.space, fullname.local, i2.call(this, t));
  };
}
function attrTweenNS(fullname, value12) {
  var t0, i0;
  function tween() {
    var i2 = value12.apply(this, arguments);
    if (i2 !== i0) t0 = (i0 = i2) && attrInterpolateNS(fullname, i2);
    return t0;
  }
  tween._value = value12;
  return tween;
}
function attrTween(name15, value12) {
  var t0, i0;
  function tween() {
    var i2 = value12.apply(this, arguments);
    if (i2 !== i0) t0 = (i0 = i2) && attrInterpolate(name15, i2);
    return t0;
  }
  tween._value = value12;
  return tween;
}
function attrTween_default(name15, value12) {
  var key = "attr." + name15;
  if (arguments.length < 2) return (key = this.tween(key)) && key._value;
  if (value12 == null) return this.tween(key, null);
  if (typeof value12 !== "function") throw new Error();
  var fullname = namespace_default(name15);
  return this.tween(key, (fullname.local ? attrTweenNS : attrTween)(fullname, value12));
}

// ../../../../../node_modules/d3-transition/src/transition/delay.js
function delayFunction(id4, value12) {
  return function() {
    init3(this, id4).delay = +value12.apply(this, arguments);
  };
}
function delayConstant(id4, value12) {
  return value12 = +value12, function() {
    init3(this, id4).delay = value12;
  };
}
function delay_default(value12) {
  var id4 = this._id;
  return arguments.length ? this.each((typeof value12 === "function" ? delayFunction : delayConstant)(id4, value12)) : get3(this.node(), id4).delay;
}

// ../../../../../node_modules/d3-transition/src/transition/duration.js
function durationFunction(id4, value12) {
  return function() {
    set2(this, id4).duration = +value12.apply(this, arguments);
  };
}
function durationConstant(id4, value12) {
  return value12 = +value12, function() {
    set2(this, id4).duration = value12;
  };
}
function duration_default(value12) {
  var id4 = this._id;
  return arguments.length ? this.each((typeof value12 === "function" ? durationFunction : durationConstant)(id4, value12)) : get3(this.node(), id4).duration;
}

// ../../../../../node_modules/d3-transition/src/transition/ease.js
function easeConstant(id4, value12) {
  if (typeof value12 !== "function") throw new Error();
  return function() {
    set2(this, id4).ease = value12;
  };
}
function ease_default(value12) {
  var id4 = this._id;
  return arguments.length ? this.each(easeConstant(id4, value12)) : get3(this.node(), id4).ease;
}

// ../../../../../node_modules/d3-transition/src/transition/easeVarying.js
function easeVarying(id4, value12) {
  return function() {
    var v = value12.apply(this, arguments);
    if (typeof v !== "function") throw new Error();
    set2(this, id4).ease = v;
  };
}
function easeVarying_default(value12) {
  if (typeof value12 !== "function") throw new Error();
  return this.each(easeVarying(this._id, value12));
}

// ../../../../../node_modules/d3-transition/src/transition/filter.js
function filter_default2(match2) {
  if (typeof match2 !== "function") match2 = matcher_default(match2);
  for (var groups = this._groups, m = groups.length, subgroups = new Array(m), j = 0; j < m; ++j) {
    for (var group4 = groups[j], n = group4.length, subgroup = subgroups[j] = [], node, i2 = 0; i2 < n; ++i2) {
      if ((node = group4[i2]) && match2.call(node, node.__data__, i2, group4)) {
        subgroup.push(node);
      }
    }
  }
  return new Transition(subgroups, this._parents, this._name, this._id);
}

// ../../../../../node_modules/d3-transition/src/transition/merge.js
function merge_default2(transition2) {
  if (transition2._id !== this._id) throw new Error();
  for (var groups0 = this._groups, groups1 = transition2._groups, m0 = groups0.length, m1 = groups1.length, m = Math.min(m0, m1), merges = new Array(m0), j = 0; j < m; ++j) {
    for (var group0 = groups0[j], group1 = groups1[j], n = group0.length, merge3 = merges[j] = new Array(n), node, i2 = 0; i2 < n; ++i2) {
      if (node = group0[i2] || group1[i2]) {
        merge3[i2] = node;
      }
    }
  }
  for (; j < m0; ++j) {
    merges[j] = groups0[j];
  }
  return new Transition(merges, this._parents, this._name, this._id);
}

// ../../../../../node_modules/d3-transition/src/transition/on.js
function start2(name15) {
  return (name15 + "").trim().split(/^|\s+/).every(function(t) {
    var i2 = t.indexOf(".");
    if (i2 >= 0) t = t.slice(0, i2);
    return !t || t === "start";
  });
}
function onFunction(id4, name15, listener) {
  var on0, on1, sit = start2(name15) ? init3 : set2;
  return function() {
    var schedule = sit(this, id4), on3 = schedule.on;
    if (on3 !== on0) (on1 = (on0 = on3).copy()).on(name15, listener);
    schedule.on = on1;
  };
}
function on_default2(name15, listener) {
  var id4 = this._id;
  return arguments.length < 2 ? get3(this.node(), id4).on.on(name15) : this.each(onFunction(id4, name15, listener));
}

// ../../../../../node_modules/d3-transition/src/transition/remove.js
function removeFunction(id4) {
  return function() {
    var parent2 = this.parentNode;
    for (var i2 in this.__transition) if (+i2 !== id4) return;
    if (parent2) parent2.removeChild(this);
  };
}
function remove_default2() {
  return this.on("end.remove", removeFunction(this._id));
}

// ../../../../../node_modules/d3-transition/src/transition/select.js
function select_default3(select9) {
  var name15 = this._name, id4 = this._id;
  if (typeof select9 !== "function") select9 = selector_default(select9);
  for (var groups = this._groups, m = groups.length, subgroups = new Array(m), j = 0; j < m; ++j) {
    for (var group4 = groups[j], n = group4.length, subgroup = subgroups[j] = new Array(n), node, subnode, i2 = 0; i2 < n; ++i2) {
      if ((node = group4[i2]) && (subnode = select9.call(node, node.__data__, i2, group4))) {
        if ("__data__" in node) subnode.__data__ = node.__data__;
        subgroup[i2] = subnode;
        schedule_default(subgroup[i2], name15, id4, i2, subgroup, get3(node, id4));
      }
    }
  }
  return new Transition(subgroups, this._parents, name15, id4);
}

// ../../../../../node_modules/d3-transition/src/transition/selectAll.js
function selectAll_default2(select9) {
  var name15 = this._name, id4 = this._id;
  if (typeof select9 !== "function") select9 = selectorAll_default(select9);
  for (var groups = this._groups, m = groups.length, subgroups = [], parents = [], j = 0; j < m; ++j) {
    for (var group4 = groups[j], n = group4.length, node, i2 = 0; i2 < n; ++i2) {
      if (node = group4[i2]) {
        for (var children3 = select9.call(node, node.__data__, i2, group4), child, inherit2 = get3(node, id4), k = 0, l = children3.length; k < l; ++k) {
          if (child = children3[k]) {
            schedule_default(child, name15, id4, k, children3, inherit2);
          }
        }
        subgroups.push(children3);
        parents.push(node);
      }
    }
  }
  return new Transition(subgroups, parents, name15, id4);
}

// ../../../../../node_modules/d3-transition/src/transition/selection.js
var Selection2 = selection_default.prototype.constructor;
function selection_default2() {
  return new Selection2(this._groups, this._parents);
}

// ../../../../../node_modules/d3-transition/src/transition/style.js
function styleNull(name15, interpolate) {
  var string00, string10, interpolate0;
  return function() {
    var string0 = styleValue(this, name15), string1 = (this.style.removeProperty(name15), styleValue(this, name15));
    return string0 === string1 ? null : string0 === string00 && string1 === string10 ? interpolate0 : interpolate0 = interpolate(string00 = string0, string10 = string1);
  };
}
function styleRemove2(name15) {
  return function() {
    this.style.removeProperty(name15);
  };
}
function styleConstant2(name15, interpolate, value1) {
  var string00, string1 = value1 + "", interpolate0;
  return function() {
    var string0 = styleValue(this, name15);
    return string0 === string1 ? null : string0 === string00 ? interpolate0 : interpolate0 = interpolate(string00 = string0, value1);
  };
}
function styleFunction2(name15, interpolate, value12) {
  var string00, string10, interpolate0;
  return function() {
    var string0 = styleValue(this, name15), value1 = value12(this), string1 = value1 + "";
    if (value1 == null) string1 = value1 = (this.style.removeProperty(name15), styleValue(this, name15));
    return string0 === string1 ? null : string0 === string00 && string1 === string10 ? interpolate0 : (string10 = string1, interpolate0 = interpolate(string00 = string0, value1));
  };
}
function styleMaybeRemove(id4, name15) {
  var on0, on1, listener0, key = "style." + name15, event = "end." + key, remove5;
  return function() {
    var schedule = set2(this, id4), on3 = schedule.on, listener = schedule.value[key] == null ? remove5 || (remove5 = styleRemove2(name15)) : void 0;
    if (on3 !== on0 || listener0 !== listener) (on1 = (on0 = on3).copy()).on(event, listener0 = listener);
    schedule.on = on1;
  };
}
function style_default2(name15, value12, priority) {
  var i2 = (name15 += "") === "transform" ? interpolateTransformCss : interpolate_default;
  return value12 == null ? this.styleTween(name15, styleNull(name15, i2)).on("end.style." + name15, styleRemove2(name15)) : typeof value12 === "function" ? this.styleTween(name15, styleFunction2(name15, i2, tweenValue(this, "style." + name15, value12))).each(styleMaybeRemove(this._id, name15)) : this.styleTween(name15, styleConstant2(name15, i2, value12), priority).on("end.style." + name15, null);
}

// ../../../../../node_modules/d3-transition/src/transition/styleTween.js
function styleInterpolate(name15, i2, priority) {
  return function(t) {
    this.style.setProperty(name15, i2.call(this, t), priority);
  };
}
function styleTween(name15, value12, priority) {
  var t, i0;
  function tween() {
    var i2 = value12.apply(this, arguments);
    if (i2 !== i0) t = (i0 = i2) && styleInterpolate(name15, i2, priority);
    return t;
  }
  tween._value = value12;
  return tween;
}
function styleTween_default(name15, value12, priority) {
  var key = "style." + (name15 += "");
  if (arguments.length < 2) return (key = this.tween(key)) && key._value;
  if (value12 == null) return this.tween(key, null);
  if (typeof value12 !== "function") throw new Error();
  return this.tween(key, styleTween(name15, value12, priority == null ? "" : priority));
}

// ../../../../../node_modules/d3-transition/src/transition/text.js
function textConstant2(value12) {
  return function() {
    this.textContent = value12;
  };
}
function textFunction2(value12) {
  return function() {
    var value1 = value12(this);
    this.textContent = value1 == null ? "" : value1;
  };
}
function text_default2(value12) {
  return this.tween("text", typeof value12 === "function" ? textFunction2(tweenValue(this, "text", value12)) : textConstant2(value12 == null ? "" : value12 + ""));
}

// ../../../../../node_modules/d3-transition/src/transition/textTween.js
function textInterpolate(i2) {
  return function(t) {
    this.textContent = i2.call(this, t);
  };
}
function textTween(value12) {
  var t0, i0;
  function tween() {
    var i2 = value12.apply(this, arguments);
    if (i2 !== i0) t0 = (i0 = i2) && textInterpolate(i2);
    return t0;
  }
  tween._value = value12;
  return tween;
}
function textTween_default(value12) {
  var key = "text";
  if (arguments.length < 1) return (key = this.tween(key)) && key._value;
  if (value12 == null) return this.tween(key, null);
  if (typeof value12 !== "function") throw new Error();
  return this.tween(key, textTween(value12));
}

// ../../../../../node_modules/d3-transition/src/transition/transition.js
function transition_default() {
  var name15 = this._name, id0 = this._id, id1 = newId();
  for (var groups = this._groups, m = groups.length, j = 0; j < m; ++j) {
    for (var group4 = groups[j], n = group4.length, node, i2 = 0; i2 < n; ++i2) {
      if (node = group4[i2]) {
        var inherit2 = get3(node, id0);
        schedule_default(node, name15, id1, i2, group4, {
          time: inherit2.time + inherit2.delay + inherit2.duration,
          delay: 0,
          duration: inherit2.duration,
          ease: inherit2.ease
        });
      }
    }
  }
  return new Transition(groups, this._parents, name15, id1);
}

// ../../../../../node_modules/d3-transition/src/transition/end.js
function end_default() {
  var on0, on1, that = this, id4 = that._id, size4 = that.size();
  return new Promise(function(resolve, reject) {
    var cancel = { value: reject }, end = { value: function() {
      if (--size4 === 0) resolve();
    } };
    that.each(function() {
      var schedule = set2(this, id4), on3 = schedule.on;
      if (on3 !== on0) {
        on1 = (on0 = on3).copy();
        on1._.cancel.push(cancel);
        on1._.interrupt.push(cancel);
        on1._.end.push(end);
      }
      schedule.on = on1;
    });
    if (size4 === 0) resolve();
  });
}

// ../../../../../node_modules/d3-transition/src/transition/index.js
var id3 = 0;
function Transition(groups, parents, name15, id4) {
  this._groups = groups;
  this._parents = parents;
  this._name = name15;
  this._id = id4;
}
function transition(name15) {
  return selection_default().transition(name15);
}
function newId() {
  return ++id3;
}
var selection_prototype = selection_default.prototype;
Transition.prototype = transition.prototype = {
  constructor: Transition,
  select: select_default3,
  selectAll: selectAll_default2,
  selectChild: selection_prototype.selectChild,
  selectChildren: selection_prototype.selectChildren,
  filter: filter_default2,
  merge: merge_default2,
  selection: selection_default2,
  transition: transition_default,
  call: selection_prototype.call,
  nodes: selection_prototype.nodes,
  node: selection_prototype.node,
  size: selection_prototype.size,
  empty: selection_prototype.empty,
  each: selection_prototype.each,
  on: on_default2,
  attr: attr_default2,
  attrTween: attrTween_default,
  style: style_default2,
  styleTween: styleTween_default,
  text: text_default2,
  textTween: textTween_default,
  remove: remove_default2,
  tween: tween_default,
  delay: delay_default,
  duration: duration_default,
  ease: ease_default,
  easeVarying: easeVarying_default,
  end: end_default,
  [Symbol.iterator]: selection_prototype[Symbol.iterator]
};

// ../../../../../node_modules/d3-ease/src/linear.js
var linear2 = (t) => +t;

// ../../../../../node_modules/d3-ease/src/quad.js
function quadIn(t) {
  return t * t;
}
function quadOut(t) {
  return t * (2 - t);
}
function quadInOut(t) {
  return ((t *= 2) <= 1 ? t * t : --t * (2 - t) + 1) / 2;
}

// ../../../../../node_modules/d3-ease/src/cubic.js
function cubicIn(t) {
  return t * t * t;
}
function cubicOut(t) {
  return --t * t * t + 1;
}
function cubicInOut(t) {
  return ((t *= 2) <= 1 ? t * t * t : (t -= 2) * t * t + 2) / 2;
}

// ../../../../../node_modules/d3-ease/src/sin.js
var pi3 = Math.PI;
var halfPi = pi3 / 2;
function sinIn(t) {
  return +t === 1 ? 1 : 1 - Math.cos(t * halfPi);
}
function sinOut(t) {
  return Math.sin(t * halfPi);
}
function sinInOut(t) {
  return (1 - Math.cos(pi3 * t)) / 2;
}

// ../../../../../node_modules/d3-ease/src/math.js
function tpmt(x4) {
  return (Math.pow(2, -10 * x4) - 9765625e-10) * 1.0009775171065494;
}

// ../../../../../node_modules/d3-ease/src/exp.js
function expIn(t) {
  return tpmt(1 - +t);
}
function expOut(t) {
  return 1 - tpmt(t);
}
function expInOut(t) {
  return ((t *= 2) <= 1 ? tpmt(1 - t) : 2 - tpmt(t - 1)) / 2;
}

// ../../../../../node_modules/d3-ease/src/circle.js
function circleIn(t) {
  return 1 - Math.sqrt(1 - t * t);
}
function circleOut(t) {
  return Math.sqrt(1 - --t * t);
}
function circleInOut(t) {
  return ((t *= 2) <= 1 ? 1 - Math.sqrt(1 - t * t) : Math.sqrt(1 - (t -= 2) * t) + 1) / 2;
}

// ../../../../../node_modules/d3-ease/src/bounce.js
var b1 = 4 / 11;
var b2 = 6 / 11;
var b3 = 8 / 11;
var b4 = 3 / 4;
var b5 = 9 / 11;
var b6 = 10 / 11;
var b7 = 15 / 16;
var b8 = 21 / 22;
var b9 = 63 / 64;
var b0 = 1 / b1 / b1;
function bounceIn(t) {
  return 1 - bounceOut(1 - t);
}
function bounceOut(t) {
  return (t = +t) < b1 ? b0 * t * t : t < b3 ? b0 * (t -= b2) * t + b4 : t < b6 ? b0 * (t -= b5) * t + b7 : b0 * (t -= b8) * t + b9;
}
function bounceInOut(t) {
  return ((t *= 2) <= 1 ? 1 - bounceOut(1 - t) : bounceOut(t - 1) + 1) / 2;
}

// ../../../../../node_modules/d3-ease/src/back.js
var overshoot = 1.70158;
var backIn = (function custom(s) {
  s = +s;
  function backIn2(t) {
    return (t = +t) * t * (s * (t - 1) + t);
  }
  backIn2.overshoot = custom;
  return backIn2;
})(overshoot);
var backOut = (function custom2(s) {
  s = +s;
  function backOut2(t) {
    return --t * t * ((t + 1) * s + t) + 1;
  }
  backOut2.overshoot = custom2;
  return backOut2;
})(overshoot);
var backInOut = (function custom3(s) {
  s = +s;
  function backInOut2(t) {
    return ((t *= 2) < 1 ? t * t * ((s + 1) * t - s) : (t -= 2) * t * ((s + 1) * t + s) + 2) / 2;
  }
  backInOut2.overshoot = custom3;
  return backInOut2;
})(overshoot);

// ../../../../../node_modules/d3-ease/src/elastic.js
var tau = 2 * Math.PI;
var amplitude = 1;
var period = 0.3;
var elasticIn = (function custom4(a2, p2) {
  var s = Math.asin(1 / (a2 = Math.max(1, a2))) * (p2 /= tau);
  function elasticIn2(t) {
    return a2 * tpmt(- --t) * Math.sin((s - t) / p2);
  }
  elasticIn2.amplitude = function(a3) {
    return custom4(a3, p2 * tau);
  };
  elasticIn2.period = function(p3) {
    return custom4(a2, p3);
  };
  return elasticIn2;
})(amplitude, period);
var elasticOut = (function custom5(a2, p2) {
  var s = Math.asin(1 / (a2 = Math.max(1, a2))) * (p2 /= tau);
  function elasticOut2(t) {
    return 1 - a2 * tpmt(t = +t) * Math.sin((t + s) / p2);
  }
  elasticOut2.amplitude = function(a3) {
    return custom5(a3, p2 * tau);
  };
  elasticOut2.period = function(p3) {
    return custom5(a2, p3);
  };
  return elasticOut2;
})(amplitude, period);
var elasticInOut = (function custom6(a2, p2) {
  var s = Math.asin(1 / (a2 = Math.max(1, a2))) * (p2 /= tau);
  function elasticInOut2(t) {
    return ((t = t * 2 - 1) < 0 ? a2 * tpmt(-t) * Math.sin((s - t) / p2) : 2 - a2 * tpmt(t) * Math.sin((s + t) / p2)) / 2;
  }
  elasticInOut2.amplitude = function(a3) {
    return custom6(a3, p2 * tau);
  };
  elasticInOut2.period = function(p3) {
    return custom6(a2, p3);
  };
  return elasticInOut2;
})(amplitude, period);

// ../../../../../node_modules/d3-transition/src/selection/transition.js
var defaultTiming = {
  time: null,
  // Set on use.
  delay: 0,
  duration: 250,
  ease: cubicInOut
};
function inherit(node, id4) {
  var timing;
  while (!(timing = node.__transition) || !(timing = timing[id4])) {
    if (!(node = node.parentNode)) {
      throw new Error(`transition ${id4} not found`);
    }
  }
  return timing;
}
function transition_default2(name15) {
  var id4, timing;
  if (name15 instanceof Transition) {
    id4 = name15._id, name15 = name15._name;
  } else {
    id4 = newId(), (timing = defaultTiming).time = now(), name15 = name15 == null ? null : name15 + "";
  }
  for (var groups = this._groups, m = groups.length, j = 0; j < m; ++j) {
    for (var group4 = groups[j], n = group4.length, node, i2 = 0; i2 < n; ++i2) {
      if (node = group4[i2]) {
        schedule_default(node, name15, id4, i2, group4, timing || inherit(node, id4));
      }
    }
  }
  return new Transition(groups, this._parents, name15, id4);
}

// ../../../../../node_modules/d3-transition/src/selection/index.js
selection_default.prototype.interrupt = interrupt_default2;
selection_default.prototype.transition = transition_default2;

// ../../../../../node_modules/d3-zoom/src/constant.js
var constant_default4 = (x4) => () => x4;

// ../../../../../node_modules/d3-zoom/src/event.js
function ZoomEvent(type, {
  sourceEvent,
  target: target6,
  transform: transform4,
  dispatch: dispatch2
}) {
  Object.defineProperties(this, {
    type: { value: type, enumerable: true, configurable: true },
    sourceEvent: { value: sourceEvent, enumerable: true, configurable: true },
    target: { value: target6, enumerable: true, configurable: true },
    transform: { value: transform4, enumerable: true, configurable: true },
    _: { value: dispatch2 }
  });
}

// ../../../../../node_modules/d3-zoom/src/transform.js
function Transform(k, x4, y4) {
  this.k = k;
  this.x = x4;
  this.y = y4;
}
Transform.prototype = {
  constructor: Transform,
  scale: function(k) {
    return k === 1 ? this : new Transform(this.k * k, this.x, this.y);
  },
  translate: function(x4, y4) {
    return x4 === 0 & y4 === 0 ? this : new Transform(this.k, this.x + this.k * x4, this.y + this.k * y4);
  },
  apply: function(point) {
    return [point[0] * this.k + this.x, point[1] * this.k + this.y];
  },
  applyX: function(x4) {
    return x4 * this.k + this.x;
  },
  applyY: function(y4) {
    return y4 * this.k + this.y;
  },
  invert: function(location2) {
    return [(location2[0] - this.x) / this.k, (location2[1] - this.y) / this.k];
  },
  invertX: function(x4) {
    return (x4 - this.x) / this.k;
  },
  invertY: function(y4) {
    return (y4 - this.y) / this.k;
  },
  rescaleX: function(x4) {
    return x4.copy().domain(x4.range().map(this.invertX, this).map(x4.invert, x4));
  },
  rescaleY: function(y4) {
    return y4.copy().domain(y4.range().map(this.invertY, this).map(y4.invert, y4));
  },
  toString: function() {
    return "translate(" + this.x + "," + this.y + ") scale(" + this.k + ")";
  }
};
var identity10 = new Transform(1, 0, 0);
transform2.prototype = Transform.prototype;
function transform2(node) {
  while (!node.__zoom) if (!(node = node.parentNode)) return identity10;
  return node.__zoom;
}

// ../../../../../node_modules/d3-zoom/src/noevent.js
function nopropagation2(event) {
  event.stopImmediatePropagation();
}
function noevent_default2(event) {
  event.preventDefault();
  event.stopImmediatePropagation();
}

// ../../../../../node_modules/d3-zoom/src/zoom.js
function defaultFilter2(event) {
  return (!event.ctrlKey || event.type === "wheel") && !event.button;
}
function defaultExtent() {
  var e = this;
  if (e instanceof SVGElement) {
    e = e.ownerSVGElement || e;
    if (e.hasAttribute("viewBox")) {
      e = e.viewBox.baseVal;
      return [[e.x, e.y], [e.x + e.width, e.y + e.height]];
    }
    return [[0, 0], [e.width.baseVal.value, e.height.baseVal.value]];
  }
  return [[0, 0], [e.clientWidth, e.clientHeight]];
}
function defaultTransform() {
  return this.__zoom || identity10;
}
function defaultWheelDelta(event) {
  return -event.deltaY * (event.deltaMode === 1 ? 0.05 : event.deltaMode ? 1 : 2e-3) * (event.ctrlKey ? 10 : 1);
}
function defaultTouchable2() {
  return navigator.maxTouchPoints || "ontouchstart" in this;
}
function defaultConstrain(transform4, extent, translateExtent) {
  var dx0 = transform4.invertX(extent[0][0]) - translateExtent[0][0], dx1 = transform4.invertX(extent[1][0]) - translateExtent[1][0], dy0 = transform4.invertY(extent[0][1]) - translateExtent[0][1], dy1 = transform4.invertY(extent[1][1]) - translateExtent[1][1];
  return transform4.translate(
    dx1 > dx0 ? (dx0 + dx1) / 2 : Math.min(0, dx0) || Math.max(0, dx1),
    dy1 > dy0 ? (dy0 + dy1) / 2 : Math.min(0, dy0) || Math.max(0, dy1)
  );
}
function zoom_default2() {
  var filter4 = defaultFilter2, extent = defaultExtent, constrain = defaultConstrain, wheelDelta = defaultWheelDelta, touchable = defaultTouchable2, scaleExtent = [0, Infinity], translateExtent = [[-Infinity, -Infinity], [Infinity, Infinity]], duration2 = 250, interpolate = zoom_default, listeners = dispatch_default2("start", "zoom", "end"), touchstarting, touchfirst, touchending, touchDelay = 500, wheelDelay = 150, clickDistance2 = 0, tapDistance = 10;
  function zoom(selection2) {
    selection2.property("__zoom", defaultTransform).on("wheel.zoom", wheeled, { passive: false }).on("mousedown.zoom", mousedowned).on("dblclick.zoom", dblclicked).filter(touchable).on("touchstart.zoom", touchstarted).on("touchmove.zoom", touchmoved).on("touchend.zoom touchcancel.zoom", touchended).style("-webkit-tap-highlight-color", "rgba(0,0,0,0)");
  }
  zoom.transform = function(collection, transform4, point, event) {
    var selection2 = collection.selection ? collection.selection() : collection;
    selection2.property("__zoom", defaultTransform);
    if (collection !== selection2) {
      schedule(collection, transform4, point, event);
    } else {
      selection2.interrupt().each(function() {
        gesture(this, arguments).event(event).start().zoom(null, typeof transform4 === "function" ? transform4.apply(this, arguments) : transform4).end();
      });
    }
  };
  zoom.scaleBy = function(selection2, k, p2, event) {
    zoom.scaleTo(selection2, function() {
      var k0 = this.__zoom.k, k1 = typeof k === "function" ? k.apply(this, arguments) : k;
      return k0 * k1;
    }, p2, event);
  };
  zoom.scaleTo = function(selection2, k, p2, event) {
    zoom.transform(selection2, function() {
      var e = extent.apply(this, arguments), t0 = this.__zoom, p0 = p2 == null ? centroid(e) : typeof p2 === "function" ? p2.apply(this, arguments) : p2, p1 = t0.invert(p0), k1 = typeof k === "function" ? k.apply(this, arguments) : k;
      return constrain(translate(scale(t0, k1), p0, p1), e, translateExtent);
    }, p2, event);
  };
  zoom.translateBy = function(selection2, x4, y4, event) {
    zoom.transform(selection2, function() {
      return constrain(this.__zoom.translate(
        typeof x4 === "function" ? x4.apply(this, arguments) : x4,
        typeof y4 === "function" ? y4.apply(this, arguments) : y4
      ), extent.apply(this, arguments), translateExtent);
    }, null, event);
  };
  zoom.translateTo = function(selection2, x4, y4, p2, event) {
    zoom.transform(selection2, function() {
      var e = extent.apply(this, arguments), t = this.__zoom, p0 = p2 == null ? centroid(e) : typeof p2 === "function" ? p2.apply(this, arguments) : p2;
      return constrain(identity10.translate(p0[0], p0[1]).scale(t.k).translate(
        typeof x4 === "function" ? -x4.apply(this, arguments) : -x4,
        typeof y4 === "function" ? -y4.apply(this, arguments) : -y4
      ), e, translateExtent);
    }, p2, event);
  };
  function scale(transform4, k) {
    k = Math.max(scaleExtent[0], Math.min(scaleExtent[1], k));
    return k === transform4.k ? transform4 : new Transform(k, transform4.x, transform4.y);
  }
  function translate(transform4, p0, p1) {
    var x4 = p0[0] - p1[0] * transform4.k, y4 = p0[1] - p1[1] * transform4.k;
    return x4 === transform4.x && y4 === transform4.y ? transform4 : new Transform(transform4.k, x4, y4);
  }
  function centroid(extent2) {
    return [(+extent2[0][0] + +extent2[1][0]) / 2, (+extent2[0][1] + +extent2[1][1]) / 2];
  }
  function schedule(transition2, transform4, point, event) {
    transition2.on("start.zoom", function() {
      gesture(this, arguments).event(event).start();
    }).on("interrupt.zoom end.zoom", function() {
      gesture(this, arguments).event(event).end();
    }).tween("zoom", function() {
      var that = this, args = arguments, g = gesture(that, args).event(event), e = extent.apply(that, args), p2 = point == null ? centroid(e) : typeof point === "function" ? point.apply(that, args) : point, w = Math.max(e[1][0] - e[0][0], e[1][1] - e[0][1]), a2 = that.__zoom, b10 = typeof transform4 === "function" ? transform4.apply(that, args) : transform4, i2 = interpolate(a2.invert(p2).concat(w / a2.k), b10.invert(p2).concat(w / b10.k));
      return function(t) {
        if (t === 1) t = b10;
        else {
          var l = i2(t), k = w / l[2];
          t = new Transform(k, p2[0] - l[0] * k, p2[1] - l[1] * k);
        }
        g.zoom(null, t);
      };
    });
  }
  function gesture(that, args, clean) {
    return !clean && that.__zooming || new Gesture(that, args);
  }
  function Gesture(that, args) {
    this.that = that;
    this.args = args;
    this.active = 0;
    this.sourceEvent = null;
    this.extent = extent.apply(that, args);
    this.taps = 0;
  }
  Gesture.prototype = {
    event: function(event) {
      if (event) this.sourceEvent = event;
      return this;
    },
    start: function() {
      if (++this.active === 1) {
        this.that.__zooming = this;
        this.emit("start");
      }
      return this;
    },
    zoom: function(key, transform4) {
      if (this.mouse && key !== "mouse") this.mouse[1] = transform4.invert(this.mouse[0]);
      if (this.touch0 && key !== "touch") this.touch0[1] = transform4.invert(this.touch0[0]);
      if (this.touch1 && key !== "touch") this.touch1[1] = transform4.invert(this.touch1[0]);
      this.that.__zoom = transform4;
      this.emit("zoom");
      return this;
    },
    end: function() {
      if (--this.active === 0) {
        delete this.that.__zooming;
        this.emit("end");
      }
      return this;
    },
    emit: function(type) {
      var d = select_default2(this.that).datum();
      listeners.call(
        type,
        this.that,
        new ZoomEvent(type, {
          sourceEvent: this.sourceEvent,
          target: zoom,
          type,
          transform: this.that.__zoom,
          dispatch: listeners
        }),
        d
      );
    }
  };
  function wheeled(event, ...args) {
    if (!filter4.apply(this, arguments)) return;
    var g = gesture(this, args).event(event), t = this.__zoom, k = Math.max(scaleExtent[0], Math.min(scaleExtent[1], t.k * Math.pow(2, wheelDelta.apply(this, arguments)))), p2 = pointer_default(event);
    if (g.wheel) {
      if (g.mouse[0][0] !== p2[0] || g.mouse[0][1] !== p2[1]) {
        g.mouse[1] = t.invert(g.mouse[0] = p2);
      }
      clearTimeout(g.wheel);
    } else if (t.k === k) return;
    else {
      g.mouse = [p2, t.invert(p2)];
      interrupt_default(this);
      g.start();
    }
    noevent_default2(event);
    g.wheel = setTimeout(wheelidled, wheelDelay);
    g.zoom("mouse", constrain(translate(scale(t, k), g.mouse[0], g.mouse[1]), g.extent, translateExtent));
    function wheelidled() {
      g.wheel = null;
      g.end();
    }
  }
  function mousedowned(event, ...args) {
    if (touchending || !filter4.apply(this, arguments)) return;
    var currentTarget2 = event.currentTarget, g = gesture(this, args, true).event(event), v = select_default2(event.view).on("mousemove.zoom", mousemoved, true).on("mouseup.zoom", mouseupped, true), p2 = pointer_default(event, currentTarget2), x0 = event.clientX, y0 = event.clientY;
    nodrag_default(event.view);
    nopropagation2(event);
    g.mouse = [p2, this.__zoom.invert(p2)];
    interrupt_default(this);
    g.start();
    function mousemoved(event2) {
      noevent_default2(event2);
      if (!g.moved) {
        var dx = event2.clientX - x0, dy = event2.clientY - y0;
        g.moved = dx * dx + dy * dy > clickDistance2;
      }
      g.event(event2).zoom("mouse", constrain(translate(g.that.__zoom, g.mouse[0] = pointer_default(event2, currentTarget2), g.mouse[1]), g.extent, translateExtent));
    }
    function mouseupped(event2) {
      v.on("mousemove.zoom mouseup.zoom", null);
      yesdrag(event2.view, g.moved);
      noevent_default2(event2);
      g.event(event2).end();
    }
  }
  function dblclicked(event, ...args) {
    if (!filter4.apply(this, arguments)) return;
    var t0 = this.__zoom, p0 = pointer_default(event.changedTouches ? event.changedTouches[0] : event, this), p1 = t0.invert(p0), k1 = t0.k * (event.shiftKey ? 0.5 : 2), t1 = constrain(translate(scale(t0, k1), p0, p1), extent.apply(this, args), translateExtent);
    noevent_default2(event);
    if (duration2 > 0) select_default2(this).transition().duration(duration2).call(schedule, t1, p0, event);
    else select_default2(this).call(zoom.transform, t1, p0, event);
  }
  function touchstarted(event, ...args) {
    if (!filter4.apply(this, arguments)) return;
    var touches = event.touches, n = touches.length, g = gesture(this, args, event.changedTouches.length === n).event(event), started, i2, t, p2;
    nopropagation2(event);
    for (i2 = 0; i2 < n; ++i2) {
      t = touches[i2], p2 = pointer_default(t, this);
      p2 = [p2, this.__zoom.invert(p2), t.identifier];
      if (!g.touch0) g.touch0 = p2, started = true, g.taps = 1 + !!touchstarting;
      else if (!g.touch1 && g.touch0[2] !== p2[2]) g.touch1 = p2, g.taps = 0;
    }
    if (touchstarting) touchstarting = clearTimeout(touchstarting);
    if (started) {
      if (g.taps < 2) touchfirst = p2[0], touchstarting = setTimeout(function() {
        touchstarting = null;
      }, touchDelay);
      interrupt_default(this);
      g.start();
    }
  }
  function touchmoved(event, ...args) {
    if (!this.__zooming) return;
    var g = gesture(this, args).event(event), touches = event.changedTouches, n = touches.length, i2, t, p2, l;
    noevent_default2(event);
    for (i2 = 0; i2 < n; ++i2) {
      t = touches[i2], p2 = pointer_default(t, this);
      if (g.touch0 && g.touch0[2] === t.identifier) g.touch0[0] = p2;
      else if (g.touch1 && g.touch1[2] === t.identifier) g.touch1[0] = p2;
    }
    t = g.that.__zoom;
    if (g.touch1) {
      var p0 = g.touch0[0], l0 = g.touch0[1], p1 = g.touch1[0], l1 = g.touch1[1], dp = (dp = p1[0] - p0[0]) * dp + (dp = p1[1] - p0[1]) * dp, dl2 = (dl2 = l1[0] - l0[0]) * dl2 + (dl2 = l1[1] - l0[1]) * dl2;
      t = scale(t, Math.sqrt(dp / dl2));
      p2 = [(p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2];
      l = [(l0[0] + l1[0]) / 2, (l0[1] + l1[1]) / 2];
    } else if (g.touch0) p2 = g.touch0[0], l = g.touch0[1];
    else return;
    g.zoom("touch", constrain(translate(t, p2, l), g.extent, translateExtent));
  }
  function touchended(event, ...args) {
    if (!this.__zooming) return;
    var g = gesture(this, args).event(event), touches = event.changedTouches, n = touches.length, i2, t;
    nopropagation2(event);
    if (touchending) clearTimeout(touchending);
    touchending = setTimeout(function() {
      touchending = null;
    }, touchDelay);
    for (i2 = 0; i2 < n; ++i2) {
      t = touches[i2];
      if (g.touch0 && g.touch0[2] === t.identifier) delete g.touch0;
      else if (g.touch1 && g.touch1[2] === t.identifier) delete g.touch1;
    }
    if (g.touch1 && !g.touch0) g.touch0 = g.touch1, delete g.touch1;
    if (g.touch0) g.touch0[1] = this.__zoom.invert(g.touch0[0]);
    else {
      g.end();
      if (g.taps === 2) {
        t = pointer_default(t, this);
        if (Math.hypot(touchfirst[0] - t[0], touchfirst[1] - t[1]) < tapDistance) {
          var p2 = select_default2(this).on("dblclick.zoom");
          if (p2) p2.apply(this, arguments);
        }
      }
    }
  }
  zoom.wheelDelta = function(_) {
    return arguments.length ? (wheelDelta = typeof _ === "function" ? _ : constant_default4(+_), zoom) : wheelDelta;
  };
  zoom.filter = function(_) {
    return arguments.length ? (filter4 = typeof _ === "function" ? _ : constant_default4(!!_), zoom) : filter4;
  };
  zoom.touchable = function(_) {
    return arguments.length ? (touchable = typeof _ === "function" ? _ : constant_default4(!!_), zoom) : touchable;
  };
  zoom.extent = function(_) {
    return arguments.length ? (extent = typeof _ === "function" ? _ : constant_default4([[+_[0][0], +_[0][1]], [+_[1][0], +_[1][1]]]), zoom) : extent;
  };
  zoom.scaleExtent = function(_) {
    return arguments.length ? (scaleExtent[0] = +_[0], scaleExtent[1] = +_[1], zoom) : [scaleExtent[0], scaleExtent[1]];
  };
  zoom.translateExtent = function(_) {
    return arguments.length ? (translateExtent[0][0] = +_[0][0], translateExtent[1][0] = +_[1][0], translateExtent[0][1] = +_[0][1], translateExtent[1][1] = +_[1][1], zoom) : [[translateExtent[0][0], translateExtent[0][1]], [translateExtent[1][0], translateExtent[1][1]]];
  };
  zoom.constrain = function(_) {
    return arguments.length ? (constrain = _, zoom) : constrain;
  };
  zoom.duration = function(_) {
    return arguments.length ? (duration2 = +_, zoom) : duration2;
  };
  zoom.interpolate = function(_) {
    return arguments.length ? (interpolate = _, zoom) : interpolate;
  };
  zoom.on = function() {
    var value12 = listeners.on.apply(listeners, arguments);
    return value12 === listeners ? zoom : value12;
  };
  zoom.clickDistance = function(_) {
    return arguments.length ? (clickDistance2 = (_ = +_) * _, zoom) : Math.sqrt(clickDistance2);
  };
  zoom.tapDistance = function(_) {
    return arguments.length ? (tapDistance = +_, zoom) : tapDistance;
  };
  return zoom;
}

// output/PSD3.Internal.Behavior.FFI/foreign.js
var simulationRegistry = /* @__PURE__ */ new Map();
function getSimulationReheat(simId) {
  const sim = simulationRegistry.get(simId);
  return sim ? sim.reheat : null;
}
function attachSimulationDragById_(element3) {
  return (simId) => () => {
    const selection2 = select_default2(element3);
    function dragstarted(event) {
      const reheat = getSimulationReheat(simId);
      if (reheat) {
        reheat();
      } else {
        console.warn(`[SimulationDrag] No simulation registered with ID: ${simId}`);
      }
      event.subject.fx = event.subject.x;
      event.subject.fy = event.subject.y;
    }
    function dragged(event) {
      event.subject.fx = event.x;
      event.subject.fy = event.y;
    }
    function dragended(event) {
      event.subject.fx = null;
      event.subject.fy = null;
    }
    const dragBehavior = drag_default().on("start", dragstarted).on("drag", dragged).on("end", dragended);
    selection2.call(dragBehavior).style("cursor", "grab");
    return element3;
  };
}
function attachSimulationDragNestedById_(element3) {
  return (simId) => () => {
    const selection2 = select_default2(element3);
    function dragstarted(event) {
      const reheat = getSimulationReheat(simId);
      if (reheat) {
        reheat();
      } else {
        console.warn(`[SimulationDragNested] No simulation registered with ID: ${simId}`);
      }
      const node = event.subject.node;
      node.fx = node.x;
      node.fy = node.y;
    }
    function dragged(event) {
      const node = event.subject.node;
      node.fx = event.x;
      node.fy = event.y;
    }
    function dragended(event) {
      const node = event.subject.node;
      node.fx = null;
      node.fy = null;
    }
    const dragBehavior = drag_default().on("start", dragstarted).on("drag", dragged).on("end", dragended);
    selection2.call(dragBehavior).style("cursor", "grab");
    return element3;
  };
}
function attachZoom_(element3) {
  return (scaleMin) => (scaleMax) => (targetSelector) => () => {
    const selection2 = select_default2(element3);
    function zoomed(event) {
      const target6 = selection2.select(targetSelector);
      target6.attr("transform", event.transform);
    }
    const zoomBehavior = zoom_default2().scaleExtent([scaleMin, scaleMax]).on("zoom", zoomed);
    selection2.call(zoomBehavior);
    return element3;
  };
}
function attachSimpleDrag_(element3) {
  return () => () => {
    const selection2 = select_default2(element3);
    let transform4 = { x: 0, y: 0 };
    function dragstarted(event) {
      select_default2(this).raise();
    }
    function dragged(event) {
      transform4.x += event.dx;
      transform4.y += event.dy;
      select_default2(this).attr("transform", `translate(${transform4.x},${transform4.y})`);
    }
    const dragBehavior = drag_default().on("start", dragstarted).on("drag", dragged);
    selection2.call(dragBehavior);
    return element3;
  };
}
function attachClick_(element3) {
  return (handler3) => () => {
    const selection2 = select_default2(element3);
    selection2.on("click", function(event) {
      handler3();
    });
    selection2.style("cursor", "pointer");
    return element3;
  };
}
function attachClickWithDatum_(element3) {
  return (handler3) => () => {
    const selection2 = select_default2(element3);
    selection2.on("click", function(event, d) {
      handler3(d)();
    });
    selection2.style("cursor", "pointer");
    return element3;
  };
}
function attachMouseEnter_(element3) {
  return (handler3) => () => {
    const selection2 = select_default2(element3);
    selection2.on("mouseenter", function(event, d) {
      handler3(d)();
    });
    return element3;
  };
}
function attachMouseLeave_(element3) {
  return (handler3) => () => {
    const selection2 = select_default2(element3);
    selection2.on("mouseleave", function(event, d) {
      handler3(d)();
    });
    return element3;
  };
}
function attachHighlight_(element3) {
  return (enterStyles) => (leaveStyles) => () => {
    const selection2 = select_default2(element3);
    selection2.on("mouseenter", function(event) {
      const sel = select_default2(this);
      sel.raise();
      enterStyles.forEach((style3) => {
        sel.attr(style3.attr, style3.value);
      });
    });
    selection2.on("mouseleave", function(event) {
      const sel = select_default2(this);
      leaveStyles.forEach((style3) => {
        sel.attr(style3.attr, style3.value);
      });
    });
    return element3;
  };
}
function attachMouseMoveWithEvent_(element3) {
  return (handler3) => () => {
    element3.addEventListener("mousemove", function(event) {
      const datum2 = this.__data__;
      handler3(datum2, event);
    });
    return element3;
  };
}
function attachMouseEnterWithEvent_(element3) {
  return (handler3) => () => {
    element3.addEventListener("mouseenter", function(event) {
      const datum2 = this.__data__;
      handler3(datum2, event);
    });
    return element3;
  };
}
function attachMouseLeaveWithEvent_(element3) {
  return (handler3) => () => {
    element3.addEventListener("mouseleave", function(event) {
      const datum2 = this.__data__;
      handler3(datum2, event);
    });
    return element3;
  };
}
function attachMouseDown_(element3) {
  return (handler3) => () => {
    const selection2 = select_default2(element3);
    selection2.on("mousedown", function(event) {
      handler3();
    });
    return element3;
  };
}
function attachMouseDownWithEvent_(element3) {
  return (handler3) => () => {
    element3.addEventListener("mousedown", function(event) {
      const datum2 = this.__data__;
      handler3(datum2, event);
    });
    return element3;
  };
}
var highlightRegistry = /* @__PURE__ */ new Map();
var HIGHLIGHT_PRIMARY = "highlight-primary";
var HIGHLIGHT_RELATED = "highlight-related";
var HIGHLIGHT_DIMMED = "highlight-dimmed";
var ALL_HIGHLIGHT_CLASSES = [HIGHLIGHT_PRIMARY, HIGHLIGHT_RELATED, HIGHLIGHT_DIMMED];
var HC_PRIMARY = 0;
var HC_RELATED = 1;
var HC_DIMMED = 2;
var HC_NEUTRAL = 3;
var TT_ON_HOVER = 0;
var TT_WHEN_PRIMARY = 1;
var TT_WHEN_RELATED = 2;
var tooltipContainer = null;
var elementTooltips = /* @__PURE__ */ new Map();
function getTooltipContainer() {
  if (!tooltipContainer) {
    tooltipContainer = document.createElement("div");
    tooltipContainer.className = "coordinated-tooltip-container";
    tooltipContainer.style.cssText = "position: fixed; top: 0; left: 0; pointer-events: none; z-index: 10000;";
    document.body.appendChild(tooltipContainer);
  }
  return tooltipContainer;
}
function createTooltipElement() {
  const tooltip = document.createElement("div");
  tooltip.className = "coordinated-tooltip";
  tooltip.style.cssText = `
    position: absolute;
    background: rgba(15, 23, 42, 0.95);
    color: #e2e8f0;
    padding: 6px 10px;
    border-radius: 4px;
    font-size: 12px;
    font-family: system-ui, -apple-system, sans-serif;
    white-space: nowrap;
    pointer-events: none;
    opacity: 0;
    transition: opacity 0.15s ease-in-out;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
    border: 1px solid rgba(148, 163, 184, 0.2);
  `;
  getTooltipContainer().appendChild(tooltip);
  return tooltip;
}
function positionTooltipNearElement(tooltip, targetElement) {
  const rect = targetElement.getBoundingClientRect();
  const tooltipRect = tooltip.getBoundingClientRect();
  let x4 = rect.left + rect.width / 2 - tooltipRect.width / 2;
  let y4 = rect.top - tooltipRect.height - 8;
  x4 = Math.max(8, Math.min(x4, window.innerWidth - tooltipRect.width - 8));
  if (y4 < 8) {
    y4 = rect.bottom + 8;
  }
  tooltip.style.left = `${x4}px`;
  tooltip.style.top = `${y4}px`;
}
function positionTooltipAtMouse(tooltip, event) {
  const x4 = event.clientX + 12;
  const y4 = event.clientY - 8;
  tooltip.style.left = `${x4}px`;
  tooltip.style.top = `${y4}px`;
}
function showTooltip(tooltip, content3) {
  tooltip.textContent = content3;
  tooltip.style.opacity = "1";
}
function hideTooltip(tooltip) {
  if (tooltip) {
    tooltip.style.opacity = "0";
  }
}
function getHighlightGroup(groupName) {
  const key = groupName || "_global";
  if (!highlightRegistry.has(key)) {
    highlightRegistry.set(key, []);
  }
  return highlightRegistry.get(key);
}
function applyHighlights(groupName, hoveredId, triggerElement, event) {
  const group4 = getHighlightGroup(groupName);
  group4.forEach((entry) => {
    const { element: element3, classifyFn, tooltipContentFn, tooltipTrigger } = entry;
    const datum2 = element3.__data__;
    const sel = select_default2(element3);
    ALL_HIGHLIGHT_CLASSES.forEach((cls) => sel.classed(cls, false));
    if (!datum2) {
      console.warn("[CoordHighlight] applyHighlights: No datum on element", element3);
      return;
    }
    const classification = classifyFn(hoveredId)(datum2);
    switch (classification) {
      case HC_PRIMARY:
        sel.classed(HIGHLIGHT_PRIMARY, true);
        break;
      case HC_RELATED:
        sel.classed(HIGHLIGHT_RELATED, true);
        break;
      case HC_DIMMED:
        sel.classed(HIGHLIGHT_DIMMED, true);
        break;
      case HC_NEUTRAL:
      default:
        break;
    }
    if (tooltipContentFn) {
      const content3 = tooltipContentFn(datum2);
      const shouldShow = tooltipTrigger === TT_ON_HOVER && element3 === triggerElement || tooltipTrigger === TT_WHEN_PRIMARY && classification === HC_PRIMARY || tooltipTrigger === TT_WHEN_RELATED && (classification === HC_PRIMARY || classification === HC_RELATED);
      if (shouldShow) {
        let tooltip = elementTooltips.get(element3);
        if (!tooltip) {
          tooltip = createTooltipElement();
          elementTooltips.set(element3, tooltip);
        }
        showTooltip(tooltip, content3);
        if (tooltipTrigger === TT_ON_HOVER && event) {
          positionTooltipAtMouse(tooltip, event);
        } else {
          positionTooltipNearElement(tooltip, element3);
        }
      } else {
        const tooltip = elementTooltips.get(element3);
        if (tooltip) {
          hideTooltip(tooltip);
        }
      }
    }
  });
}
function clearHighlightsInGroup(groupName) {
  const group4 = getHighlightGroup(groupName);
  group4.forEach((entry) => {
    const sel = select_default2(entry.element);
    ALL_HIGHLIGHT_CLASSES.forEach((cls) => sel.classed(cls, false));
    const tooltip = elementTooltips.get(entry.element);
    if (tooltip) {
      hideTooltip(tooltip);
    }
  });
}
function attachCoordinatedHighlight_(element3) {
  return (identifyFn) => (classifyFn) => (groupName) => (tooltipContentFn) => (tooltipTrigger) => () => {
    const sel = select_default2(element3);
    const group4 = groupName;
    const groupKey = group4 || "_global";
    const entry = { element: element3, identifyFn, classifyFn, tooltipContentFn, tooltipTrigger };
    getHighlightGroup(group4).push(entry);
    sel.on("mouseenter.coordinated", function(event) {
      const d = this.__data__;
      if (!d) {
        console.warn("[CoordHighlight] mouseenter: No datum on element");
        return;
      }
      const id4 = identifyFn(d);
      applyHighlights(group4, id4, element3, event);
    });
    sel.on("mouseleave.coordinated", function(event) {
      clearHighlightsInGroup(group4);
    });
    return element3;
  };
}

// output/PSD3.Internal.Behavior.Types/index.js
var OnHover = /* @__PURE__ */ (function() {
  function OnHover2() {
  }
  ;
  OnHover2.value = new OnHover2();
  return OnHover2;
})();
var WhenPrimary = /* @__PURE__ */ (function() {
  function WhenPrimary2() {
  }
  ;
  WhenPrimary2.value = new WhenPrimary2();
  return WhenPrimary2;
})();
var WhenRelated = /* @__PURE__ */ (function() {
  function WhenRelated2() {
  }
  ;
  WhenRelated2.value = new WhenRelated2();
  return WhenRelated2;
})();
var Primary = /* @__PURE__ */ (function() {
  function Primary2() {
  }
  ;
  Primary2.value = new Primary2();
  return Primary2;
})();
var Related = /* @__PURE__ */ (function() {
  function Related2() {
  }
  ;
  Related2.value = new Related2();
  return Related2;
})();
var Dimmed = /* @__PURE__ */ (function() {
  function Dimmed2() {
  }
  ;
  Dimmed2.value = new Dimmed2();
  return Dimmed2;
})();
var Neutral = /* @__PURE__ */ (function() {
  function Neutral2() {
  }
  ;
  Neutral2.value = new Neutral2();
  return Neutral2;
})();
var SimpleDrag = /* @__PURE__ */ (function() {
  function SimpleDrag2() {
  }
  ;
  SimpleDrag2.value = new SimpleDrag2();
  return SimpleDrag2;
})();
var SimulationDrag = /* @__PURE__ */ (function() {
  function SimulationDrag2(value0) {
    this.value0 = value0;
  }
  ;
  SimulationDrag2.create = function(value0) {
    return new SimulationDrag2(value0);
  };
  return SimulationDrag2;
})();
var SimulationDragNested = /* @__PURE__ */ (function() {
  function SimulationDragNested2(value0) {
    this.value0 = value0;
  }
  ;
  SimulationDragNested2.create = function(value0) {
    return new SimulationDragNested2(value0);
  };
  return SimulationDragNested2;
})();
var Zoom = /* @__PURE__ */ (function() {
  function Zoom2(value0) {
    this.value0 = value0;
  }
  ;
  Zoom2.create = function(value0) {
    return new Zoom2(value0);
  };
  return Zoom2;
})();
var Drag = /* @__PURE__ */ (function() {
  function Drag2(value0) {
    this.value0 = value0;
  }
  ;
  Drag2.create = function(value0) {
    return new Drag2(value0);
  };
  return Drag2;
})();
var Click = /* @__PURE__ */ (function() {
  function Click2(value0) {
    this.value0 = value0;
  }
  ;
  Click2.create = function(value0) {
    return new Click2(value0);
  };
  return Click2;
})();
var ClickWithDatum = /* @__PURE__ */ (function() {
  function ClickWithDatum2(value0) {
    this.value0 = value0;
  }
  ;
  ClickWithDatum2.create = function(value0) {
    return new ClickWithDatum2(value0);
  };
  return ClickWithDatum2;
})();
var MouseEnter = /* @__PURE__ */ (function() {
  function MouseEnter2(value0) {
    this.value0 = value0;
  }
  ;
  MouseEnter2.create = function(value0) {
    return new MouseEnter2(value0);
  };
  return MouseEnter2;
})();
var MouseLeave = /* @__PURE__ */ (function() {
  function MouseLeave2(value0) {
    this.value0 = value0;
  }
  ;
  MouseLeave2.create = function(value0) {
    return new MouseLeave2(value0);
  };
  return MouseLeave2;
})();
var Highlight = /* @__PURE__ */ (function() {
  function Highlight2(value0) {
    this.value0 = value0;
  }
  ;
  Highlight2.create = function(value0) {
    return new Highlight2(value0);
  };
  return Highlight2;
})();
var CoordinatedHighlight = /* @__PURE__ */ (function() {
  function CoordinatedHighlight2(value0) {
    this.value0 = value0;
  }
  ;
  CoordinatedHighlight2.create = function(value0) {
    return new CoordinatedHighlight2(value0);
  };
  return CoordinatedHighlight2;
})();
var MouseMoveWithInfo = /* @__PURE__ */ (function() {
  function MouseMoveWithInfo2(value0) {
    this.value0 = value0;
  }
  ;
  MouseMoveWithInfo2.create = function(value0) {
    return new MouseMoveWithInfo2(value0);
  };
  return MouseMoveWithInfo2;
})();
var MouseEnterWithInfo = /* @__PURE__ */ (function() {
  function MouseEnterWithInfo2(value0) {
    this.value0 = value0;
  }
  ;
  MouseEnterWithInfo2.create = function(value0) {
    return new MouseEnterWithInfo2(value0);
  };
  return MouseEnterWithInfo2;
})();
var MouseLeaveWithInfo = /* @__PURE__ */ (function() {
  function MouseLeaveWithInfo2(value0) {
    this.value0 = value0;
  }
  ;
  MouseLeaveWithInfo2.create = function(value0) {
    return new MouseLeaveWithInfo2(value0);
  };
  return MouseLeaveWithInfo2;
})();
var MouseDown = /* @__PURE__ */ (function() {
  function MouseDown2(value0) {
    this.value0 = value0;
  }
  ;
  MouseDown2.create = function(value0) {
    return new MouseDown2(value0);
  };
  return MouseDown2;
})();
var MouseDownWithInfo = /* @__PURE__ */ (function() {
  function MouseDownWithInfo2(value0) {
    this.value0 = value0;
  }
  ;
  MouseDownWithInfo2.create = function(value0) {
    return new MouseDownWithInfo2(value0);
  };
  return MouseDownWithInfo2;
})();

// output/PSD3.Internal.Selection.Join/index.js
var unsafeIndex2 = /* @__PURE__ */ unsafeIndex();
var foldlWithIndex2 = /* @__PURE__ */ foldlWithIndex(foldableWithIndexArray);
var computeJoinWithKey = function(dictEq) {
  var eq3 = eq(dictEq);
  return function(newData) {
    return function(oldBindings) {
      return function(keyFn) {
        var processNewDatum = function(newIndex) {
          return function(state3) {
            return function(datum2) {
              var newKey = keyFn(datum2);
              var v = findIndex(function(v1) {
                return eq3(keyFn(v1.datum))(newKey);
              })(state3.remainingOld);
              if (v instanceof Nothing) {
                var enterBinding = {
                  datum: datum2,
                  newIndex
                };
                return {
                  remainingOld: state3.remainingOld,
                  matchedIndices: state3.matchedIndices,
                  update: state3.update,
                  enter: cons(enterBinding)(state3.enter)
                };
              }
              ;
              if (v instanceof Just) {
                var newRemaining = fromMaybe(state3.remainingOld)(deleteAt(v.value0)(state3.remainingOld));
                var matched = unsafeIndex2(state3.remainingOld)(v.value0);
                var updateBinding = {
                  element: matched.element,
                  oldDatum: datum2,
                  newDatum: datum2,
                  newIndex
                };
                return {
                  enter: state3.enter,
                  update: cons(updateBinding)(state3.update),
                  remainingOld: newRemaining,
                  matchedIndices: cons(v.value0)(state3.matchedIndices)
                };
              }
              ;
              throw new Error("Failed pattern match at PSD3.Internal.Selection.Join (line 167, column 9 - line 189, column 18): " + [v.constructor.name]);
            };
          };
        };
        var matchResult = foldlWithIndex2(processNewDatum)({
          remainingOld: oldBindings,
          enter: [],
          update: [],
          matchedIndices: []
        })(newData);
        return {
          enter: reverse(matchResult.enter),
          update: reverse(matchResult.update),
          exit: matchResult.remainingOld
        };
      };
    };
  };
};
var computeJoin = function(dictEq) {
  var eq3 = eq(dictEq);
  return function(newData) {
    return function(oldBindings) {
      var processNewDatum = function(newIndex) {
        return function(state3) {
          return function(datum2) {
            var v = findIndex(function(v1) {
              return eq3(v1.datum)(datum2);
            })(state3.remainingOld);
            if (v instanceof Nothing) {
              var enterBinding = {
                datum: datum2,
                newIndex
              };
              return {
                remainingOld: state3.remainingOld,
                matchedIndices: state3.matchedIndices,
                update: state3.update,
                enter: cons(enterBinding)(state3.enter)
              };
            }
            ;
            if (v instanceof Just) {
              var newRemaining = fromMaybe(state3.remainingOld)(deleteAt(v.value0)(state3.remainingOld));
              var matched = unsafeIndex2(state3.remainingOld)(v.value0);
              var updateBinding = {
                element: matched.element,
                oldDatum: datum2,
                newDatum: datum2,
                newIndex
              };
              return {
                enter: state3.enter,
                update: cons(updateBinding)(state3.update),
                remainingOld: newRemaining,
                matchedIndices: cons(v.value0)(state3.matchedIndices)
              };
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Join (line 100, column 7 - line 122, column 16): " + [v.constructor.name]);
          };
        };
      };
      var matchResult = foldlWithIndex2(processNewDatum)({
        remainingOld: oldBindings,
        enter: [],
        update: [],
        matchedIndices: []
      })(newData);
      return {
        enter: reverse(matchResult.enter),
        update: reverse(matchResult.update),
        exit: matchResult.remainingOld
      };
    };
  };
};

// output/PSD3.Internal.Transition.FFI/foreign.js
function createTransition_(duration2) {
  return function(delay) {
    return function(easingName) {
      return function(element3) {
        return function() {
          let transition2 = select_default2(element3).transition();
          transition2 = transition2.duration(duration2);
          if (delay != null) {
            transition2 = transition2.delay(delay);
          }
          if (easingName != null) {
            const easingFn = getD3EasingFunction(easingName);
            if (easingFn) {
              transition2 = transition2.ease(easingFn);
            }
          }
          return transition2;
        };
      };
    };
  };
}
function transitionSetAttribute_(name15) {
  return function(value12) {
    return function(transition2) {
      return function() {
        transition2.attr(name15, value12);
      };
    };
  };
}
function transitionRemove_(transition2) {
  return function() {
    transition2.remove();
  };
}
function getD3EasingFunction(name15) {
  const easingMap = {
    // Linear
    "linear": linear2,
    // Polynomial (Quad, Cubic)
    "quad": quadInOut,
    "quadIn": quadIn,
    "quadOut": quadOut,
    "quadInOut": quadInOut,
    "cubic": cubicInOut,
    "cubicIn": cubicIn,
    "cubicOut": cubicOut,
    "cubicInOut": cubicInOut,
    // Sinusoidal
    "sin": sinInOut,
    "sinIn": sinIn,
    "sinOut": sinOut,
    "sinInOut": sinInOut,
    // Exponential
    "exp": expInOut,
    "expIn": expIn,
    "expOut": expOut,
    "expInOut": expInOut,
    // Circular
    "circle": circleInOut,
    "circleIn": circleIn,
    "circleOut": circleOut,
    "circleInOut": circleInOut,
    // Elastic
    "elastic": elasticOut,
    "elasticIn": elasticIn,
    "elasticOut": elasticOut,
    "elasticInOut": elasticInOut,
    // Back
    "back": backInOut,
    "backIn": backIn,
    "backOut": backOut,
    "backInOut": backInOut,
    // Bounce
    "bounce": bounceOut,
    "bounceIn": bounceIn,
    "bounceOut": bounceOut,
    "bounceInOut": bounceInOut
  };
  return easingMap[name15];
}

// output/PSD3.Internal.Transition.Types/index.js
var Linear = /* @__PURE__ */ (function() {
  function Linear2() {
  }
  ;
  Linear2.value = new Linear2();
  return Linear2;
})();
var Cubic = /* @__PURE__ */ (function() {
  function Cubic2() {
  }
  ;
  Cubic2.value = new Cubic2();
  return Cubic2;
})();
var CubicIn = /* @__PURE__ */ (function() {
  function CubicIn2() {
  }
  ;
  CubicIn2.value = new CubicIn2();
  return CubicIn2;
})();
var CubicOut = /* @__PURE__ */ (function() {
  function CubicOut2() {
  }
  ;
  CubicOut2.value = new CubicOut2();
  return CubicOut2;
})();
var CubicInOut = /* @__PURE__ */ (function() {
  function CubicInOut2() {
  }
  ;
  CubicInOut2.value = new CubicInOut2();
  return CubicInOut2;
})();
var Quad = /* @__PURE__ */ (function() {
  function Quad2() {
  }
  ;
  Quad2.value = new Quad2();
  return Quad2;
})();
var QuadIn = /* @__PURE__ */ (function() {
  function QuadIn2() {
  }
  ;
  QuadIn2.value = new QuadIn2();
  return QuadIn2;
})();
var QuadOut = /* @__PURE__ */ (function() {
  function QuadOut2() {
  }
  ;
  QuadOut2.value = new QuadOut2();
  return QuadOut2;
})();
var QuadInOut = /* @__PURE__ */ (function() {
  function QuadInOut2() {
  }
  ;
  QuadInOut2.value = new QuadInOut2();
  return QuadInOut2;
})();
var Sin = /* @__PURE__ */ (function() {
  function Sin2() {
  }
  ;
  Sin2.value = new Sin2();
  return Sin2;
})();
var SinIn = /* @__PURE__ */ (function() {
  function SinIn2() {
  }
  ;
  SinIn2.value = new SinIn2();
  return SinIn2;
})();
var SinOut = /* @__PURE__ */ (function() {
  function SinOut2() {
  }
  ;
  SinOut2.value = new SinOut2();
  return SinOut2;
})();
var SinInOut = /* @__PURE__ */ (function() {
  function SinInOut2() {
  }
  ;
  SinInOut2.value = new SinInOut2();
  return SinInOut2;
})();
var Exp = /* @__PURE__ */ (function() {
  function Exp2() {
  }
  ;
  Exp2.value = new Exp2();
  return Exp2;
})();
var ExpIn = /* @__PURE__ */ (function() {
  function ExpIn2() {
  }
  ;
  ExpIn2.value = new ExpIn2();
  return ExpIn2;
})();
var ExpOut = /* @__PURE__ */ (function() {
  function ExpOut2() {
  }
  ;
  ExpOut2.value = new ExpOut2();
  return ExpOut2;
})();
var ExpInOut = /* @__PURE__ */ (function() {
  function ExpInOut2() {
  }
  ;
  ExpInOut2.value = new ExpInOut2();
  return ExpInOut2;
})();
var Circle2 = /* @__PURE__ */ (function() {
  function Circle3() {
  }
  ;
  Circle3.value = new Circle3();
  return Circle3;
})();
var CircleIn = /* @__PURE__ */ (function() {
  function CircleIn2() {
  }
  ;
  CircleIn2.value = new CircleIn2();
  return CircleIn2;
})();
var CircleOut = /* @__PURE__ */ (function() {
  function CircleOut2() {
  }
  ;
  CircleOut2.value = new CircleOut2();
  return CircleOut2;
})();
var CircleInOut = /* @__PURE__ */ (function() {
  function CircleInOut2() {
  }
  ;
  CircleInOut2.value = new CircleInOut2();
  return CircleInOut2;
})();
var Elastic = /* @__PURE__ */ (function() {
  function Elastic2() {
  }
  ;
  Elastic2.value = new Elastic2();
  return Elastic2;
})();
var ElasticIn = /* @__PURE__ */ (function() {
  function ElasticIn2() {
  }
  ;
  ElasticIn2.value = new ElasticIn2();
  return ElasticIn2;
})();
var ElasticOut = /* @__PURE__ */ (function() {
  function ElasticOut2() {
  }
  ;
  ElasticOut2.value = new ElasticOut2();
  return ElasticOut2;
})();
var ElasticInOut = /* @__PURE__ */ (function() {
  function ElasticInOut2() {
  }
  ;
  ElasticInOut2.value = new ElasticInOut2();
  return ElasticInOut2;
})();
var Back = /* @__PURE__ */ (function() {
  function Back2() {
  }
  ;
  Back2.value = new Back2();
  return Back2;
})();
var BackIn = /* @__PURE__ */ (function() {
  function BackIn2() {
  }
  ;
  BackIn2.value = new BackIn2();
  return BackIn2;
})();
var BackOut = /* @__PURE__ */ (function() {
  function BackOut2() {
  }
  ;
  BackOut2.value = new BackOut2();
  return BackOut2;
})();
var BackInOut = /* @__PURE__ */ (function() {
  function BackInOut2() {
  }
  ;
  BackInOut2.value = new BackInOut2();
  return BackInOut2;
})();
var Bounce = /* @__PURE__ */ (function() {
  function Bounce2() {
  }
  ;
  Bounce2.value = new Bounce2();
  return Bounce2;
})();
var BounceIn = /* @__PURE__ */ (function() {
  function BounceIn2() {
  }
  ;
  BounceIn2.value = new BounceIn2();
  return BounceIn2;
})();
var BounceOut = /* @__PURE__ */ (function() {
  function BounceOut2() {
  }
  ;
  BounceOut2.value = new BounceOut2();
  return BounceOut2;
})();
var BounceInOut = /* @__PURE__ */ (function() {
  function BounceInOut2() {
  }
  ;
  BounceInOut2.value = new BounceInOut2();
  return BounceInOut2;
})();
var showEasing = {
  show: function(v) {
    if (v instanceof Linear) {
      return "linear";
    }
    ;
    if (v instanceof Cubic) {
      return "cubic";
    }
    ;
    if (v instanceof CubicIn) {
      return "cubicIn";
    }
    ;
    if (v instanceof CubicOut) {
      return "cubicOut";
    }
    ;
    if (v instanceof CubicInOut) {
      return "cubicInOut";
    }
    ;
    if (v instanceof Quad) {
      return "quad";
    }
    ;
    if (v instanceof QuadIn) {
      return "quadIn";
    }
    ;
    if (v instanceof QuadOut) {
      return "quadOut";
    }
    ;
    if (v instanceof QuadInOut) {
      return "quadInOut";
    }
    ;
    if (v instanceof Sin) {
      return "sin";
    }
    ;
    if (v instanceof SinIn) {
      return "sinIn";
    }
    ;
    if (v instanceof SinOut) {
      return "sinOut";
    }
    ;
    if (v instanceof SinInOut) {
      return "sinInOut";
    }
    ;
    if (v instanceof Exp) {
      return "exp";
    }
    ;
    if (v instanceof ExpIn) {
      return "expIn";
    }
    ;
    if (v instanceof ExpOut) {
      return "expOut";
    }
    ;
    if (v instanceof ExpInOut) {
      return "expInOut";
    }
    ;
    if (v instanceof Circle2) {
      return "circle";
    }
    ;
    if (v instanceof CircleIn) {
      return "circleIn";
    }
    ;
    if (v instanceof CircleOut) {
      return "circleOut";
    }
    ;
    if (v instanceof CircleInOut) {
      return "circleInOut";
    }
    ;
    if (v instanceof Elastic) {
      return "elastic";
    }
    ;
    if (v instanceof ElasticIn) {
      return "elasticIn";
    }
    ;
    if (v instanceof ElasticOut) {
      return "elasticOut";
    }
    ;
    if (v instanceof ElasticInOut) {
      return "elasticInOut";
    }
    ;
    if (v instanceof Back) {
      return "back";
    }
    ;
    if (v instanceof BackIn) {
      return "backIn";
    }
    ;
    if (v instanceof BackOut) {
      return "backOut";
    }
    ;
    if (v instanceof BackInOut) {
      return "backInOut";
    }
    ;
    if (v instanceof Bounce) {
      return "bounce";
    }
    ;
    if (v instanceof BounceIn) {
      return "bounceIn";
    }
    ;
    if (v instanceof BounceOut) {
      return "bounceOut";
    }
    ;
    if (v instanceof BounceInOut) {
      return "bounceInOut";
    }
    ;
    throw new Error("Failed pattern match at PSD3.Internal.Transition.Types (line 91, column 1 - line 124, column 35): " + [v.constructor.name]);
  }
};

// output/PSD3.Internal.Transition.FFI/index.js
var map18 = /* @__PURE__ */ map(functorMaybe);
var maybeEasingToNullable = /* @__PURE__ */ (function() {
  var $6 = map18(show(showEasing));
  return function($7) {
    return toNullable($6($7));
  };
})();

// output/Web.DOM.Document/foreign.js
var getEffProp3 = function(name15) {
  return function(doc) {
    return function() {
      return doc[name15];
    };
  };
};
var url = getEffProp3("URL");
var documentURI = getEffProp3("documentURI");
var origin2 = getEffProp3("origin");
var compatMode = getEffProp3("compatMode");
var characterSet = getEffProp3("characterSet");
var contentType = getEffProp3("contentType");
var _documentElement2 = getEffProp3("documentElement");
function createElement2(localName2) {
  return function(doc) {
    return function() {
      return doc.createElement(localName2);
    };
  };
}
function _createElementNS(ns) {
  return function(qualifiedName) {
    return function(doc) {
      return function() {
        return doc.createElementNS(ns, qualifiedName);
      };
    };
  };
}

// output/Web.DOM.Document/index.js
var createElementNS = function($6) {
  return _createElementNS(toNullable($6));
};

// output/Web.DOM.NodeList/foreign.js
function toArray(list) {
  return function() {
    return [].slice.call(list);
  };
}

// output/Web.UIEvent.MouseEvent/foreign.js
function clientX(e) {
  return e.clientX;
}
function clientY(e) {
  return e.clientY;
}
function pageX(e) {
  return e.pageX;
}
function pageY(e) {
  return e.pageY;
}

// output/PSD3.Internal.Selection.Operations/index.js
var bind5 = /* @__PURE__ */ bind(bindEffect);
var pure9 = /* @__PURE__ */ pure(applicativeEffect);
var traverse_7 = /* @__PURE__ */ traverse_(applicativeEffect)(foldableArray);
var traverse2 = /* @__PURE__ */ traverse(traversableArray)(applicativeEffect);
var append12 = /* @__PURE__ */ append(semigroupArray);
var mapFlipped1 = /* @__PURE__ */ mapFlipped(functorMaybe);
var compare2 = /* @__PURE__ */ compare(ordInt);
var mapFlipped2 = /* @__PURE__ */ mapFlipped(functorArray);
var show3 = /* @__PURE__ */ show(showNumber);
var show1 = /* @__PURE__ */ show(showBoolean);
var unwrap3 = /* @__PURE__ */ unwrap();
var traverseWithIndex_2 = /* @__PURE__ */ traverseWithIndex_(applicativeEffect)(foldableWithIndexArray);
var discard5 = /* @__PURE__ */ discard(discardUnit);
var $$void7 = /* @__PURE__ */ $$void(functorEffect);
var unsafeIndex3 = /* @__PURE__ */ unsafeIndex();
var traverseWithIndex2 = /* @__PURE__ */ traverseWithIndex(traversableWithIndexArray)(applicativeEffect);
var mod2 = /* @__PURE__ */ mod(euclideanRingInt);
var union3 = /* @__PURE__ */ union(ordString);
var map19 = /* @__PURE__ */ map(functorArray);
var insert5 = /* @__PURE__ */ insert(ordString);
var liftEffect7 = /* @__PURE__ */ liftEffect(monadEffectEffect);
var log4 = /* @__PURE__ */ log3(monadEffectEffect);
var show22 = /* @__PURE__ */ show(showInt);
var join3 = /* @__PURE__ */ join(bindArray);
var tooltipTriggerToInt = function(v) {
  if (v instanceof OnHover) {
    return 0;
  }
  ;
  if (v instanceof WhenPrimary) {
    return 1;
  }
  ;
  if (v instanceof WhenRelated) {
    return 2;
  }
  ;
  throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 918, column 1 - line 918, column 45): " + [v.constructor.name]);
};
var stringToElementType = function(v) {
  if (v === "circle") {
    return Circle.value;
  }
  ;
  if (v === "rect") {
    return Rect.value;
  }
  ;
  if (v === "path") {
    return Path.value;
  }
  ;
  if (v === "line") {
    return Line.value;
  }
  ;
  if (v === "text") {
    return Text2.value;
  }
  ;
  if (v === "g") {
    return Group.value;
  }
  ;
  if (v === "svg") {
    return SVG.value;
  }
  ;
  if (v === "defs") {
    return Defs.value;
  }
  ;
  if (v === "linearGradient") {
    return LinearGradient.value;
  }
  ;
  if (v === "stop") {
    return Stop.value;
  }
  ;
  if (v === "pattern") {
    return PatternFill.value;
  }
  ;
  if (v === "div") {
    return Div.value;
  }
  ;
  if (v === "span") {
    return Span.value;
  }
  ;
  if (v === "table") {
    return Table.value;
  }
  ;
  if (v === "tr") {
    return Tr.value;
  }
  ;
  if (v === "td") {
    return Td.value;
  }
  ;
  if (v === "th") {
    return Th.value;
  }
  ;
  if (v === "tbody") {
    return Tbody.value;
  }
  ;
  if (v === "thead") {
    return Thead.value;
  }
  ;
  return Group.value;
};
var selectElement2 = function(dictMonadEffect) {
  var liftEffect12 = liftEffect(dictMonadEffect);
  return function(element3) {
    return liftEffect12(function __do2() {
      var htmlDoc = bind5(windowImpl)(document2)();
      var doc = toDocument(htmlDoc);
      return new EmptySelection({
        parentElements: [element3],
        document: doc
      });
    });
  };
};
var select6 = function(dictMonadEffect) {
  var liftEffect12 = liftEffect(dictMonadEffect);
  return function(selector) {
    return liftEffect12(function __do2() {
      var htmlDoc = bind5(windowImpl)(document2)();
      var doc = toDocument(htmlDoc);
      var parentNode3 = toParentNode(htmlDoc);
      var maybeElement = querySelector(selector)(parentNode3)();
      if (maybeElement instanceof Nothing) {
        return new EmptySelection({
          parentElements: [],
          document: doc
        });
      }
      ;
      if (maybeElement instanceof Just) {
        return new EmptySelection({
          parentElements: [maybeElement.value0],
          document: doc
        });
      }
      ;
      throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 92, column 3 - line 100, column 8): " + [maybeElement.constructor.name]);
    });
  };
};
var remove2 = function(dictMonadEffect) {
  var liftEffect12 = liftEffect(dictMonadEffect);
  return function(v) {
    return liftEffect12((function() {
      var v1 = (function() {
        if (v instanceof ExitingSelection) {
          return v.value0;
        }
        ;
        throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 348, column 34 - line 349, column 30): " + [v.constructor.name]);
      })();
      return traverse_7(function(element3) {
        var node = toNode2(element3);
        return function __do2() {
          var maybeParent = parentNode2(node)();
          if (maybeParent instanceof Just) {
            return removeChild2(node)(maybeParent.value0)();
          }
          ;
          if (maybeParent instanceof Nothing) {
            return unit;
          }
          ;
          throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 353, column 5 - line 355, column 27): " + [maybeParent.constructor.name]);
        };
      })(v1.elements);
    })());
  };
};
var remove1 = /* @__PURE__ */ remove2(monadEffectEffect);
var querySelectorAllElements = function(selector) {
  return function(parents) {
    return function __do2() {
      var nodeArrays = traverse2(function(parent2) {
        var parentNode3 = toParentNode2(parent2);
        return function __do3() {
          var nodeList = querySelectorAll(selector)(parentNode3)();
          var nodes = toArray(nodeList)();
          return mapMaybe(fromNode)(nodes);
        };
      })(parents)();
      return concat(nodeArrays);
    };
  };
};
var merge = function(dictMonadEffect) {
  var pure14 = pure(dictMonadEffect.Monad0().Applicative0());
  return function(v) {
    return function(v1) {
      var v2 = (function() {
        if (v instanceof BoundSelection) {
          return v.value0;
        }
        ;
        throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 563, column 68 - line 564, column 28): " + [v.constructor.name]);
      })();
      var v3 = (function() {
        if (v1 instanceof BoundSelection) {
          return v1.value0;
        }
        ;
        throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 566, column 53 - line 567, column 28): " + [v1.constructor.name]);
      })();
      return pure14(new BoundSelection({
        elements: append12(v2.elements)(v3.elements),
        data: append12(v2.data)(v3.data),
        indices: Nothing.value,
        document: v2.document
      }));
    };
  };
};
var joinDataWithKey = function(dictMonadEffect) {
  var liftEffect12 = liftEffect(dictMonadEffect);
  return function(dictFoldable) {
    var fromFoldable3 = fromFoldable(dictFoldable);
    return function(dictEq) {
      var computeJoinWithKey2 = computeJoinWithKey(dictEq);
      return function(foldableData) {
        return function(keyFn) {
          return function(selector) {
            return function(v) {
              return liftEffect12((function() {
                var v1 = (function() {
                  if (v instanceof EmptySelection) {
                    return v.value0;
                  }
                  ;
                  throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 687, column 55 - line 688, column 28): " + [v.constructor.name]);
                })();
                return function __do2() {
                  var existingElements = querySelectorAllElements(selector)(v1.parentElements)();
                  var oldBindings = traverse2(function(element3) {
                    return function __do3() {
                      var nullableDatum = getElementData_(element3)();
                      var maybeDatum = toMaybe(nullableDatum);
                      return {
                        element: element3,
                        datum: maybeDatum
                      };
                    };
                  })(existingElements)();
                  var validOldBindings = mapMaybe(function(v2) {
                    return mapFlipped1(v2.datum)(function(d) {
                      return {
                        element: v2.element,
                        datum: d
                      };
                    });
                  })(oldBindings);
                  var newDataArray = fromFoldable3(foldableData);
                  var joinSets = computeJoinWithKey2(newDataArray)(validOldBindings)(keyFn);
                  var sortedEnter = sortBy(function(a2) {
                    return function(b10) {
                      return compare2(a2.newIndex)(b10.newIndex);
                    };
                  })(joinSets.enter);
                  var enterSelection = new PendingSelection({
                    parentElements: v1.parentElements,
                    pendingData: mapFlipped2(sortedEnter)(function(v2) {
                      return v2.datum;
                    }),
                    indices: new Just(mapFlipped2(sortedEnter)(function(v2) {
                      return v2.newIndex;
                    })),
                    document: v1.document
                  });
                  var sortedUpdate = sortBy(function(a2) {
                    return function(b10) {
                      return compare2(a2.newIndex)(b10.newIndex);
                    };
                  })(joinSets.update);
                  var updateSelection = new BoundSelection({
                    elements: mapFlipped2(sortedUpdate)(function(v2) {
                      return v2.element;
                    }),
                    data: mapFlipped2(sortedUpdate)(function(v2) {
                      return v2.newDatum;
                    }),
                    indices: new Just(mapFlipped2(sortedUpdate)(function(v2) {
                      return v2.newIndex;
                    })),
                    document: v1.document
                  });
                  var exitSelection = new ExitingSelection({
                    elements: mapFlipped2(joinSets.exit)(function(v2) {
                      return v2.element;
                    }),
                    data: mapFlipped2(joinSets.exit)(function(v2) {
                      return v2.datum;
                    }),
                    document: v1.document
                  });
                  return new JoinResult({
                    enter: enterSelection,
                    update: updateSelection,
                    exit: exitSelection
                  });
                };
              })());
            };
          };
        };
      };
    };
  };
};
var joinDataWithKey1 = /* @__PURE__ */ joinDataWithKey(monadEffectEffect)(foldableArray)(eqString);
var joinData = function(dictMonadEffect) {
  var liftEffect12 = liftEffect(dictMonadEffect);
  return function(dictFoldable) {
    var fromFoldable3 = fromFoldable(dictFoldable);
    return function(dictOrd) {
      var computeJoin2 = computeJoin(dictOrd.Eq0());
      return function(foldableData) {
        return function(selector) {
          return function(v) {
            return liftEffect12((function() {
              var v1 = (function() {
                if (v instanceof EmptySelection) {
                  return v.value0;
                }
                ;
                throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 598, column 55 - line 599, column 28): " + [v.constructor.name]);
              })();
              return function __do2() {
                var existingElements = querySelectorAllElements(selector)(v1.parentElements)();
                var oldBindings = traverse2(function(element3) {
                  return function __do3() {
                    var nullableDatum = getElementData_(element3)();
                    var maybeDatum = toMaybe(nullableDatum);
                    return {
                      element: element3,
                      datum: maybeDatum
                    };
                  };
                })(existingElements)();
                var validOldBindings = mapMaybe(function(v2) {
                  return mapFlipped1(v2.datum)(function(d) {
                    return {
                      element: v2.element,
                      datum: d
                    };
                  });
                })(oldBindings);
                var newDataArray = fromFoldable3(foldableData);
                var joinSets = computeJoin2(newDataArray)(validOldBindings);
                var sortedEnter = sortBy(function(a2) {
                  return function(b10) {
                    return compare2(a2.newIndex)(b10.newIndex);
                  };
                })(joinSets.enter);
                var enterSelection = new PendingSelection({
                  parentElements: v1.parentElements,
                  pendingData: mapFlipped2(sortedEnter)(function(v2) {
                    return v2.datum;
                  }),
                  indices: new Just(mapFlipped2(sortedEnter)(function(v2) {
                    return v2.newIndex;
                  })),
                  document: v1.document
                });
                var sortedUpdate = sortBy(function(a2) {
                  return function(b10) {
                    return compare2(a2.newIndex)(b10.newIndex);
                  };
                })(joinSets.update);
                var updateSelection = new BoundSelection({
                  elements: mapFlipped2(sortedUpdate)(function(v2) {
                    return v2.element;
                  }),
                  data: mapFlipped2(sortedUpdate)(function(v2) {
                    return v2.newDatum;
                  }),
                  indices: new Just(mapFlipped2(sortedUpdate)(function(v2) {
                    return v2.newIndex;
                  })),
                  document: v1.document
                });
                var exitSelection = new ExitingSelection({
                  elements: mapFlipped2(joinSets.exit)(function(v2) {
                    return v2.element;
                  }),
                  data: mapFlipped2(joinSets.exit)(function(v2) {
                    return v2.datum;
                  }),
                  document: v1.document
                });
                return new JoinResult({
                  enter: enterSelection,
                  update: updateSelection,
                  exit: exitSelection
                });
              };
            })());
          };
        };
      };
    };
  };
};
var joinData1 = /* @__PURE__ */ joinData(monadEffectEffect)(foldableArray);
var highlightClassToInt = function(v) {
  if (v instanceof Primary) {
    return 0;
  }
  ;
  if (v instanceof Related) {
    return 1;
  }
  ;
  if (v instanceof Dimmed) {
    return 2;
  }
  ;
  if (v instanceof Neutral) {
    return 3;
  }
  ;
  throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 910, column 1 - line 910, column 45): " + [v.constructor.name]);
};
var getExitingElementDatumPairs = function(v) {
  var v1 = (function() {
    if (v instanceof ExitingSelection) {
      return v.value0;
    }
    ;
    throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1238, column 52 - line 1239, column 30): " + [v.constructor.name]);
  })();
  return zipWith(Tuple.create)(v1.elements)(v1.data);
};
var getElementsFromBoundSelection = function(v) {
  if (v instanceof BoundSelection) {
    return v.value0.elements;
  }
  ;
  throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1261, column 17 - line 1262, column 35): " + [v.constructor.name]);
};
var getDocument = function(v) {
  if (v instanceof EmptySelection) {
    return pure9(v.value0.document);
  }
  ;
  if (v instanceof BoundSelection) {
    return pure9(v.value0.document);
  }
  ;
  if (v instanceof PendingSelection) {
    return pure9(v.value0.document);
  }
  ;
  if (v instanceof ExitingSelection) {
    return pure9(v.value0.document);
  }
  ;
  throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 876, column 1 - line 876, column 82): " + [v.constructor.name]);
};
var selectAll = function(dictMonadEffect) {
  var liftEffect12 = liftEffect(dictMonadEffect);
  return function(selector) {
    return function(v) {
      return liftEffect12(function __do2() {
        var doc = getDocument(v)();
        var parentElems = (function() {
          if (v instanceof EmptySelection) {
            return v.value0.parentElements;
          }
          ;
          if (v instanceof BoundSelection) {
            return v.value0.elements;
          }
          ;
          if (v instanceof PendingSelection) {
            return v.value0.parentElements;
          }
          ;
          if (v instanceof ExitingSelection) {
            return v.value0.elements;
          }
          ;
          throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 146, column 19 - line 150, column 48): " + [v.constructor.name]);
        })();
        return new EmptySelection({
          parentElements: parentElems,
          document: doc
        });
      });
    };
  };
};
var selectAllWithData = function(dictMonadEffect) {
  var liftEffect12 = liftEffect(dictMonadEffect);
  return function(selector) {
    return function(v) {
      return liftEffect12(function __do2() {
        var doc = getDocument(v)();
        var elements = (function() {
          if (v instanceof EmptySelection) {
            return querySelectorAllElements(selector)(v.value0.parentElements)();
          }
          ;
          if (v instanceof BoundSelection) {
            return querySelectorAllElements(selector)(v.value0.elements)();
          }
          ;
          if (v instanceof PendingSelection) {
            return querySelectorAllElements(selector)(v.value0.parentElements)();
          }
          ;
          if (v instanceof ExitingSelection) {
            return querySelectorAllElements(selector)(v.value0.elements)();
          }
          ;
          throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 178, column 15 - line 186, column 50): " + [v.constructor.name]);
        })();
        var dataArray = traverse2(function(el) {
          return function __do3() {
            var nullableDatum = getElementData_(el)();
            var v1 = toMaybe(nullableDatum);
            if (v1 instanceof Just) {
              return v1.value0;
            }
            ;
            if (v1 instanceof Nothing) {
              return unit;
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 192, column 16 - line 194, column 39): " + [v1.constructor.name]);
          };
        })(elements)();
        return new BoundSelection({
          elements,
          data: dataArray,
          indices: Nothing.value,
          document: doc
        });
      });
    };
  };
};
var getBoundElementDatumPairs = function(v) {
  var v1 = (function() {
    if (v instanceof BoundSelection) {
      return v.value0;
    }
    ;
    throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1250, column 52 - line 1251, column 28): " + [v.constructor.name]);
  })();
  return zipWith(Tuple.create)(v1.elements)(v1.data);
};
var elementTypeToString = function(v) {
  if (v instanceof Circle) {
    return "circle";
  }
  ;
  if (v instanceof Rect) {
    return "rect";
  }
  ;
  if (v instanceof Path) {
    return "path";
  }
  ;
  if (v instanceof Line) {
    return "line";
  }
  ;
  if (v instanceof Text2) {
    return "text";
  }
  ;
  if (v instanceof Group) {
    return "g";
  }
  ;
  if (v instanceof SVG) {
    return "svg";
  }
  ;
  if (v instanceof Defs) {
    return "defs";
  }
  ;
  if (v instanceof LinearGradient) {
    return "linearGradient";
  }
  ;
  if (v instanceof Stop) {
    return "stop";
  }
  ;
  if (v instanceof PatternFill) {
    return "pattern";
  }
  ;
  if (v instanceof Div) {
    return "div";
  }
  ;
  if (v instanceof Span) {
    return "span";
  }
  ;
  if (v instanceof Table) {
    return "table";
  }
  ;
  if (v instanceof Tr) {
    return "tr";
  }
  ;
  if (v instanceof Td) {
    return "td";
  }
  ;
  if (v instanceof Th) {
    return "th";
  }
  ;
  if (v instanceof Tbody) {
    return "tbody";
  }
  ;
  if (v instanceof Thead) {
    return "thead";
  }
  ;
  throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1073, column 1 - line 1073, column 45): " + [v.constructor.name]);
};
var createElementWithNS = function(elemType) {
  return function(doc) {
    var v = elementContext(elemType);
    if (v instanceof SVGContext) {
      return createElementNS(new Just("http://www.w3.org/2000/svg"))(elementTypeToString(elemType))(doc);
    }
    ;
    if (v instanceof HTMLContext) {
      return createElement2(elementTypeToString(elemType))(doc);
    }
    ;
    throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 886, column 3 - line 892, column 64): " + [v.constructor.name]);
  };
};
var clear3 = function(dictMonadEffect) {
  var liftEffect12 = liftEffect(dictMonadEffect);
  return function(selector) {
    return liftEffect12(clearElement_(selector));
  };
};
var attributeValueToString = function(v) {
  if (v instanceof StringValue) {
    return v.value0;
  }
  ;
  if (v instanceof NumberValue) {
    return show3(v.value0);
  }
  ;
  if (v instanceof BooleanValue) {
    return show1(v.value0);
  }
  ;
  throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1068, column 1 - line 1068, column 51): " + [v.constructor.name]);
};
var applyTransitionToSingleElement = function(config) {
  return function(index6) {
    return function(element3) {
      return function(datum2) {
        return function(attrs) {
          var baseDelay = maybe(0)(unwrap3)(config.delay);
          var stagger = fromMaybe(0)(config.staggerDelay);
          var effectiveDelay = baseDelay + toNumber(index6) * stagger;
          var delayNullable = toNullable(new Just(effectiveDelay));
          var easingNullable = maybeEasingToNullable(config.easing);
          return function __do2() {
            var transition2 = createTransition_(config.duration)(delayNullable)(easingNullable)(element3)();
            return traverse_7(function(attr5) {
              if (attr5 instanceof StaticAttr) {
                return transitionSetAttribute_(attr5.value0)(attributeValueToString(attr5.value1))(transition2);
              }
              ;
              if (attr5 instanceof DataAttr) {
                return transitionSetAttribute_(attr5.value0)(attributeValueToString(attr5.value2(datum2)))(transition2);
              }
              ;
              if (attr5 instanceof IndexedAttr) {
                return transitionSetAttribute_(attr5.value0)(attributeValueToString(attr5.value2(datum2)(index6)))(transition2);
              }
              ;
              throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1182, column 30 - line 1190, column 101): " + [attr5.constructor.name]);
            })(attrs)();
          };
        };
      };
    };
  };
};
var applyExitTransitionToElements = function(config) {
  return function(elementDatumPairs) {
    return function(attrs) {
      var baseDelay = maybe(0)(unwrap3)(config.delay);
      var stagger = fromMaybe(0)(config.staggerDelay);
      var easingNullable = maybeEasingToNullable(config.easing);
      return traverseWithIndex_2(function(index6) {
        return function(v) {
          var effectiveDelay = baseDelay + toNumber(index6) * stagger;
          var delayNullable = toNullable(new Just(effectiveDelay));
          return function __do2() {
            var transition2 = createTransition_(config.duration)(delayNullable)(easingNullable)(v.value0)();
            traverse_7(function(attr5) {
              if (attr5 instanceof StaticAttr) {
                return transitionSetAttribute_(attr5.value0)(attributeValueToString(attr5.value1))(transition2);
              }
              ;
              if (attr5 instanceof DataAttr) {
                return transitionSetAttribute_(attr5.value0)(attributeValueToString(attr5.value2(v.value1)))(transition2);
              }
              ;
              if (attr5 instanceof IndexedAttr) {
                return transitionSetAttribute_(attr5.value0)(attributeValueToString(attr5.value2(v.value1)(index6)))(transition2);
              }
              ;
              throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1218, column 32 - line 1226, column 103): " + [attr5.constructor.name]);
            })(attrs)();
            return transitionRemove_(transition2)();
          };
        };
      })(elementDatumPairs);
    };
  };
};
var applyBehaviorToElement = function(v) {
  return function(v1) {
    if (v instanceof Zoom) {
      return $$void7(attachZoom_(v1)(v.value0.scaleExtent.value0)(v.value0.scaleExtent.value1)(v.value0.targetSelector));
    }
    ;
    if (v instanceof Drag && v.value0 instanceof SimpleDrag) {
      return $$void7(attachSimpleDrag_(v1)(unit));
    }
    ;
    if (v instanceof Drag && v.value0 instanceof SimulationDrag) {
      return $$void7(attachSimulationDragById_(v1)(v.value0.value0));
    }
    ;
    if (v instanceof Drag && v.value0 instanceof SimulationDragNested) {
      return $$void7(attachSimulationDragNestedById_(v1)(v.value0.value0));
    }
    ;
    if (v instanceof Click) {
      return $$void7(attachClick_(v1)(v.value0));
    }
    ;
    if (v instanceof ClickWithDatum) {
      return $$void7(attachClickWithDatum_(v1)(v.value0));
    }
    ;
    if (v instanceof MouseEnter) {
      return $$void7(attachMouseEnter_(v1)(v.value0));
    }
    ;
    if (v instanceof MouseLeave) {
      return $$void7(attachMouseLeave_(v1)(v.value0));
    }
    ;
    if (v instanceof Highlight) {
      return $$void7(attachHighlight_(v1)(v.value0.enter)(v.value0.leave));
    }
    ;
    if (v instanceof MouseMoveWithInfo) {
      return $$void7(attachMouseMoveWithEvent_(v1)(function(d, evt) {
        return v.value0({
          datum: d,
          clientX: toNumber(clientX(evt)),
          clientY: toNumber(clientY(evt)),
          pageX: toNumber(pageX(evt)),
          pageY: toNumber(pageY(evt)),
          offsetX: offsetX(evt),
          offsetY: offsetY(evt)
        })();
      }));
    }
    ;
    if (v instanceof MouseEnterWithInfo) {
      return $$void7(attachMouseEnterWithEvent_(v1)(function(d, evt) {
        return v.value0({
          datum: d,
          clientX: toNumber(clientX(evt)),
          clientY: toNumber(clientY(evt)),
          pageX: toNumber(pageX(evt)),
          pageY: toNumber(pageY(evt)),
          offsetX: offsetX(evt),
          offsetY: offsetY(evt)
        })();
      }));
    }
    ;
    if (v instanceof MouseLeaveWithInfo) {
      return $$void7(attachMouseLeaveWithEvent_(v1)(function(d, evt) {
        return v.value0({
          datum: d,
          clientX: toNumber(clientX(evt)),
          clientY: toNumber(clientY(evt)),
          pageX: toNumber(pageX(evt)),
          pageY: toNumber(pageY(evt)),
          offsetX: offsetX(evt),
          offsetY: offsetY(evt)
        })();
      }));
    }
    ;
    if (v instanceof MouseDown) {
      return $$void7(attachMouseDown_(v1)(v.value0));
    }
    ;
    if (v instanceof MouseDownWithInfo) {
      return $$void7(attachMouseDownWithEvent_(v1)(function(d, evt) {
        return v.value0({
          datum: d,
          clientX: toNumber(clientX(evt)),
          clientY: toNumber(clientY(evt)),
          pageX: toNumber(pageX(evt)),
          pageY: toNumber(pageY(evt)),
          offsetX: offsetX(evt),
          offsetY: offsetY(evt)
        })();
      }));
    }
    ;
    if (v instanceof CoordinatedHighlight) {
      var tooltipTrigger = (function() {
        if (v.value0.tooltip instanceof Just) {
          return tooltipTriggerToInt(v.value0.tooltip.value0.showWhen);
        }
        ;
        if (v.value0.tooltip instanceof Nothing) {
          return 0;
        }
        ;
        throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1002, column 22 - line 1004, column 19): " + [v.value0.tooltip.constructor.name]);
      })();
      var tooltipContentFn = mapFlipped1(v.value0.tooltip)(function(v2) {
        return v2.content;
      });
      var classifyAsInt = function(hoveredId) {
        return function(datum2) {
          return highlightClassToInt(v.value0.classify(hoveredId)(datum2));
        };
      };
      return $$void7(attachCoordinatedHighlight_(v1)(v.value0.identify)(classifyAsInt)(toNullable(v.value0.group))(toNullable(tooltipContentFn))(tooltipTrigger));
    }
    ;
    throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 927, column 1 - line 927, column 81): " + [v.constructor.name, v1.constructor.name]);
  };
};
var on2 = function(behavior) {
  return function(v) {
    var getElements = function(v1) {
      if (v1 instanceof EmptySelection) {
        return v1.value0.parentElements;
      }
      ;
      if (v1 instanceof BoundSelection) {
        return v1.value0.elements;
      }
      ;
      if (v1 instanceof PendingSelection) {
        return v1.value0.parentElements;
      }
      ;
      if (v1 instanceof ExitingSelection) {
        return v1.value0.elements;
      }
      ;
      throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1038, column 3 - line 1038, column 59): " + [v1.constructor.name]);
    };
    var elements = getElements(v);
    return function __do2() {
      traverse_7(applyBehaviorToElement(behavior))(elements)();
      return v;
    };
  };
};
var applyAttributes = function(element3) {
  return function(datum2) {
    return function(index6) {
      return function(attrs) {
        return traverse_7(function(attr5) {
          if (attr5 instanceof StaticAttr) {
            var $422 = attr5.value0 === "textContent";
            if ($422) {
              return setTextContent_(attributeValueToString(attr5.value1))(element3);
            }
            ;
            return setAttribute2(attr5.value0)(attributeValueToString(attr5.value1))(element3);
          }
          ;
          if (attr5 instanceof DataAttr) {
            var val = attributeValueToString(attr5.value2(datum2));
            var $425 = attr5.value0 === "textContent";
            if ($425) {
              return setTextContent_(val)(element3);
            }
            ;
            return setAttribute2(attr5.value0)(val)(element3);
          }
          ;
          if (attr5 instanceof IndexedAttr) {
            var val = attributeValueToString(attr5.value2(datum2)(index6));
            var $429 = attr5.value0 === "textContent";
            if ($429) {
              return setTextContent_(val)(element3);
            }
            ;
            return setAttribute2(attr5.value0)(val)(element3);
          }
          ;
          throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1049, column 30 - line 1066, column 51): " + [attr5.constructor.name]);
        })(attrs);
      };
    };
  };
};
var applyPerDatumAttrs = function(dictMonadEffect) {
  var liftEffect12 = liftEffect(dictMonadEffect);
  return function(mkAttrs) {
    return function(v) {
      return liftEffect12((function() {
        if (v instanceof BoundSelection) {
          var paired = zipWith(Tuple.create)(v.value0.data)(v.value0.elements);
          return function __do2() {
            traverseWithIndex_2(function(index6) {
              return function(v1) {
                var attrs = mkAttrs(v1.value0);
                return applyAttributes(v1.value1)(v1.value0)(index6)(attrs);
              };
            })(paired)();
            return v;
          };
        }
        ;
        return pure9(v);
      })());
    };
  };
};
var setAttrs = function(dictMonadEffect) {
  var liftEffect12 = liftEffect(dictMonadEffect);
  return function(attrs) {
    return function(v) {
      return liftEffect12((function() {
        var v1 = (function() {
          if (v instanceof BoundSelection) {
            return v.value0;
          }
          ;
          throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 284, column 76 - line 285, column 28): " + [v.constructor.name]);
        })();
        var paired = zipWith(Tuple.create)(v1.data)(v1.elements);
        return function __do2() {
          traverseWithIndex_2(function(arrayIndex) {
            return function(v2) {
              var logicalIndex = (function() {
                if (v1.indices instanceof Just) {
                  return unsafeIndex3(v1.indices.value0)(arrayIndex);
                }
                ;
                if (v1.indices instanceof Nothing) {
                  return arrayIndex;
                }
                ;
                throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 290, column 22 - line 292, column 30): " + [v1.indices.constructor.name]);
              })();
              return applyAttributes(v2.value1)(v2.value0)(logicalIndex)(attrs);
            };
          })(paired)();
          return new BoundSelection({
            elements: v1.elements,
            data: v1.data,
            indices: v1.indices,
            document: v1.document
          });
        };
      })());
    };
  };
};
var setAttrs1 = /* @__PURE__ */ setAttrs(monadEffectEffect);
var setAttrsExit = function(dictMonadEffect) {
  var liftEffect12 = liftEffect(dictMonadEffect);
  return function(attrs) {
    return function(v) {
      return liftEffect12((function() {
        var v1 = (function() {
          if (v instanceof ExitingSelection) {
            return v.value0;
          }
          ;
          throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 319, column 67 - line 320, column 30): " + [v.constructor.name]);
        })();
        var paired = zipWith(Tuple.create)(v1.data)(v1.elements);
        return function __do2() {
          traverseWithIndex_2(function(index6) {
            return function(v2) {
              return applyAttributes(v2.value1)(v2.value0)(index6)(attrs);
            };
          })(paired)();
          return new ExitingSelection({
            elements: v1.elements,
            data: v1.data,
            document: v1.document
          });
        };
      })());
    };
  };
};
var setAttrsExit1 = /* @__PURE__ */ setAttrsExit(monadEffectEffect);
var updateElementFromTree = function(element3) {
  return function(datum2) {
    return function(index6) {
      return function(tree) {
        return function(doc) {
          return function __do2() {
            setElementData_(datum2)(element3)();
            if (tree instanceof Node2) {
              return applyAttributes(element3)(datum2)(index6)(tree.value0.attrs)();
            }
            ;
            return unit;
          };
        };
      };
    };
  };
};
var renderTemplatesForBoundSelection = function(dictOrd) {
  return function(templateFn) {
    return function(boundSel) {
      var v = (function() {
        if (boundSel instanceof BoundSelection) {
          return boundSel.value0;
        }
        ;
        throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1966, column 66 - line 1967, column 32): " + [boundSel.constructor.name]);
      })();
      return traverseWithIndex2(function(idx) {
        return function(datum2) {
          var v1 = index(v.elements)(idx);
          if (v1 instanceof Nothing) {
            return unsafeCrashWith("renderTemplatesForBoundSelection: index out of bounds");
          }
          ;
          if (v1 instanceof Just) {
            var tree = templateFn(datum2);
            return function __do2() {
              updateElementFromTree(v1.value0)(datum2)(idx)(tree)(v.document)();
              return v1.value0;
            };
          }
          ;
          throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1972, column 9 - line 1981, column 25): " + [v1.constructor.name]);
        };
      })(v.data);
    };
  };
};
var appendChildWithDatum = function(dictMonadEffect) {
  var liftEffect12 = liftEffect(dictMonadEffect);
  return function(elemType) {
    return function(attrs) {
      return function(datumOpt) {
        return function(logicalIndex) {
          return function(v) {
            return liftEffect12((function() {
              var v1 = (function() {
                if (v instanceof EmptySelection) {
                  return v.value0;
                }
                ;
                throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 458, column 55 - line 459, column 28): " + [v.constructor.name]);
              })();
              return function __do2() {
                var elements = traverse2(function(parent2) {
                  return function __do3() {
                    var element3 = createElementWithNS(elemType)(v1.document)();
                    var datum2 = (function() {
                      if (datumOpt instanceof Just) {
                        return datumOpt.value0;
                      }
                      ;
                      if (datumOpt instanceof Nothing) {
                        return unit;
                      }
                      ;
                      throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 466, column 15 - line 468, column 49): " + [datumOpt.constructor.name]);
                    })();
                    applyAttributes(element3)(datum2)(logicalIndex)(attrs)();
                    var elementNode = toNode2(element3);
                    var parentNode3 = toNode2(parent2);
                    appendChild(elementNode)(parentNode3)();
                    return element3;
                  };
                })(v1.parentElements)();
                return new EmptySelection({
                  parentElements: elements,
                  document: v1.document
                });
              };
            })());
          };
        };
      };
    };
  };
};
var appendChildWithDatum1 = /* @__PURE__ */ appendChildWithDatum(monadEffectEffect);
var renderTemplatesForPendingSelection = function(dictOrd) {
  return function(templateFn) {
    return function(pendingSel) {
      var v = (function() {
        if (pendingSel instanceof PendingSelection) {
          return pendingSel.value0;
        }
        ;
        throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1909, column 68 - line 1910, column 34): " + [pendingSel.constructor.name]);
      })();
      var $494 = $$null(v.parentElements);
      if ($494) {
        return pure9([]);
      }
      ;
      return traverseWithIndex2(function(idx) {
        return function(datum2) {
          var parentIdx = mod2(idx)(length(v.parentElements));
          var v1 = index(v.parentElements)(parentIdx);
          if (v1 instanceof Nothing) {
            return unsafeCrashWith("renderTemplatesForPendingSelection: no parent elements");
          }
          ;
          if (v1 instanceof Just) {
            var tree = templateFn(datum2);
            var singleParentSel = new EmptySelection({
              parentElements: [v1.value0],
              document: v.document
            });
            return function __do2() {
              var v2 = renderNodeHelperWithDatum(dictOrd)(singleParentSel)(tree)(new Just(datum2))(idx)();
              setElementData_(datum2)(v2.value0)();
              return new Tuple(v2.value0, v2.value1);
            };
          }
          ;
          throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1922, column 11 - line 1942, column 51): " + [v1.constructor.name]);
        };
      })(v.pendingData);
    };
  };
};
var renderNodeHelperWithDatum = function(dictOrd) {
  return function(v) {
    return function(v1) {
      return function(v2) {
        return function(v3) {
          if (v1 instanceof Node2) {
            return function __do2() {
              var childSel = appendChildWithDatum1(v1.value0.elemType)(v1.value0.attrs)(v2)(v3)(v)();
              var element3 = (function() {
                if (childSel instanceof EmptySelection) {
                  var v42 = head(childSel.value0.parentElements);
                  if (v42 instanceof Just) {
                    return v42.value0;
                  }
                  ;
                  if (v42 instanceof Nothing) {
                    return unsafeCrashWith("renderTree: appendChild returned empty selection");
                  }
                  ;
                  throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1287, column 29 - line 1289, column 102): " + [v42.constructor.name]);
                }
                ;
                return unsafeCrashWith("renderTree: appendChild should return EmptySelection");
              })();
              traverse_7(function(behavior) {
                return applyBehaviorToElement(behavior)(element3);
              })(v1.value0.behaviors)();
              var childMaps = traverse2(function(child) {
                return renderNodeHelperWithDatum(dictOrd)(childSel)(child)(v2)(v3);
              })(v1.value0.children)();
              var combinedChildMap = foldl2(union3)(empty2)(map19(snd)(childMaps));
              var selectionsMap = (function() {
                if (v1.value0.name instanceof Just) {
                  return insert5(v1.value0.name.value0)(childSel)(combinedChildMap);
                }
                ;
                if (v1.value0.name instanceof Nothing) {
                  return combinedChildMap;
                }
                ;
                throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1302, column 21 - line 1304, column 34): " + [v1.value0.name.constructor.name]);
              })();
              return new Tuple(element3, selectionsMap);
            };
          }
          ;
          if (v1 instanceof Join2) {
            return renderNodeHelper(dictOrd)(v)(v1);
          }
          ;
          if (v1 instanceof NestedJoin) {
            return renderNodeHelper(dictOrd)(v)(v1);
          }
          ;
          if (v1 instanceof UpdateJoin) {
            return renderNodeHelper(dictOrd)(v)(v1);
          }
          ;
          if (v1 instanceof UpdateNestedJoin) {
            return renderNodeHelper(dictOrd)(v)(v1);
          }
          ;
          if (v1 instanceof LocalCoordSpace) {
            return renderNodeHelper(dictOrd)(v)(v1);
          }
          ;
          if (v1 instanceof ConditionalRender && v2 instanceof Just) {
            var v4 = find2(function(c) {
              return c.predicate(v2.value0);
            })(v1.value0.cases);
            if (v4 instanceof Just) {
              var chosenTree = v4.value0.spec(v2.value0);
              return renderNodeHelperWithDatum(dictOrd)(v)(chosenTree)(new Just(v2.value0))(v3);
            }
            ;
            if (v4 instanceof Nothing) {
              var doc = (function() {
                if (v instanceof EmptySelection) {
                  return v.value0.document;
                }
                ;
                if (v instanceof EmptySelection) {
                  return v.value0.document;
                }
                ;
                throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1329, column 33 - line 1329, column 80): " + [v.constructor.name]);
              })();
              return function __do2() {
                var dummyElement = createElementWithNS(Group.value)(doc)();
                return new Tuple(dummyElement, empty2);
              };
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1319, column 3 - line 1331, column 42): " + [v4.constructor.name]);
          }
          ;
          if (v1 instanceof ConditionalRender && v2 instanceof Nothing) {
            return renderNodeHelper(dictOrd)(v)(new ConditionalRender({
              cases: []
            }));
          }
          ;
          throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1271, column 1 - line 1278, column 74): " + [v.constructor.name, v1.constructor.name, v2.constructor.name, v3.constructor.name]);
        };
      };
    };
  };
};
var renderNodeHelper = function(dictOrd) {
  var joinData22 = joinData1(dictOrd);
  var renderTemplatesForBoundSelection1 = renderTemplatesForBoundSelection(dictOrd);
  return function(v) {
    return function(v1) {
      if (v1 instanceof Node2) {
        return renderNodeHelperWithDatum(dictOrd)(v)(new Node2(v1.value0))(Nothing.value)(0);
      }
      ;
      if (v1 instanceof Join2) {
        return function __do2() {
          var v2 = joinData22(v1.value0.joinData)(v1.value0.key)(v)();
          remove1(v2.value0.exit)();
          var enterElementsAndMaps = renderTemplatesForPendingSelection(dictOrd)(v1.value0.template)(v2.value0.enter)();
          var enterElements = map19(fst)(enterElementsAndMaps);
          var enterChildMaps = map19(snd)(enterElementsAndMaps);
          var updateElements = renderTemplatesForBoundSelection1(v1.value0.template)(v2.value0.update)();
          var allElements = append12(enterElements)(updateElements);
          var combinedChildMap = foldl2(union3)(empty2)(enterChildMaps);
          var doc2 = (function() {
            if (v2.value0.enter instanceof PendingSelection) {
              return v2.value0.enter.value0.document;
            }
            ;
            if (v2.value0.update instanceof BoundSelection) {
              return v2.value0.update.value0.document;
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1400, column 12 - line 1401, column 43): " + [v2.value0.update.constructor.name]);
          })();
          var allData = (function() {
            if (v2.value0.enter instanceof PendingSelection) {
              return v2.value0.enter.value0.pendingData;
            }
            ;
            return [];
          })();
          var updateData = (function() {
            if (v2.value0.update instanceof BoundSelection) {
              return v2.value0.update.value0.data;
            }
            ;
            return [];
          })();
          var boundSel = new BoundSelection({
            elements: allElements,
            data: append12(allData)(updateData),
            indices: new Just(range2(0)(length(allElements) - 1 | 0)),
            document: doc2
          });
          var selectionsMap = insert5(v1.value0.name)(boundSel)(combinedChildMap);
          var firstElement = (function() {
            var v3 = head(allElements);
            if (v3 instanceof Just) {
              return v3.value0;
            }
            ;
            if (v3 instanceof Nothing) {
              return createElementWithNS(Group.value)(doc2)();
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1426, column 19 - line 1428, column 45): " + [v3.constructor.name]);
          })();
          return new Tuple(firstElement, selectionsMap);
        };
      }
      ;
      if (v1 instanceof NestedJoin) {
        return function __do2() {
          var v2 = joinData22(v1.value0.joinData)(v1.value0.key)(v)();
          var elementsAndMaps = renderNestedTemplatesForPendingSelection(dictOrd)(v1.value0.decompose)(v1.value0.template)(stringToElementType(v1.value0.key))(v2.value0.enter)();
          var elements = map19(fst)(elementsAndMaps);
          var childMaps = map19(snd)(elementsAndMaps);
          var combinedChildMap = foldl2(union3)(empty2)(childMaps);
          var v3 = (function() {
            if (v2.value0.enter instanceof PendingSelection) {
              return v2.value0.enter.value0;
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1452, column 52 - line 1453, column 34): " + [v2.value0.enter.constructor.name]);
          })();
          var boundSel = new BoundSelection({
            elements,
            data: v3.pendingData,
            indices: new Just(range2(0)(length(elements) - 1 | 0)),
            document: v3.document
          });
          var selectionsMap = insert5(v1.value0.name)(boundSel)(combinedChildMap);
          var firstElement = (function() {
            var v4 = head(elements);
            if (v4 instanceof Just) {
              return v4.value0;
            }
            ;
            if (v4 instanceof Nothing) {
              return createElementWithNS(Group.value)(v3.document)();
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1468, column 19 - line 1470, column 45): " + [v4.constructor.name]);
          })();
          return new Tuple(firstElement, selectionsMap);
        };
      }
      ;
      if (v1 instanceof UpdateJoin) {
        return function __do2() {
          var v2 = (function() {
            if (v1.value0.keyFn instanceof Just) {
              return joinDataWithKey1(v1.value0.joinData)(v1.value0.keyFn.value0)(v1.value0.key)(v)();
            }
            ;
            if (v1.value0.keyFn instanceof Nothing) {
              return joinData22(v1.value0.joinData)(v1.value0.key)(v)();
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1480, column 5 - line 1482, column 67): " + [v1.value0.keyFn.constructor.name]);
          })();
          liftEffect7((function() {
            var enterCount = (function() {
              if (v2.value0.enter instanceof PendingSelection) {
                return length(v2.value0.enter.value0.pendingData);
              }
              ;
              return 0;
            })();
            var updateCount = (function() {
              if (v2.value0.update instanceof BoundSelection) {
                return length(v2.value0.update.value0.data);
              }
              ;
              return 0;
            })();
            var exitCount = (function() {
              if (v2.value0.exit instanceof BoundSelection) {
                return length(v2.value0.exit.value0.data);
              }
              ;
              if (v2.value0.exit instanceof ExitingSelection) {
                return length(v2.value0.exit.value0.data);
              }
              ;
              return 0;
            })();
            return log4("Tree API UpdateJoin '" + (v1.value0.name + ("': enter=" + (show22(enterCount) + (", update=" + (show22(updateCount) + (", exit=" + show22(exitCount))))))));
          })())();
          (function() {
            if (v1.value0.behaviors.exit instanceof Just) {
              if (v1.value0.behaviors.exit.value0.transition instanceof Just) {
                var pairs = getExitingElementDatumPairs(v2.value0.exit);
                return liftEffect7(applyExitTransitionToElements(v1.value0.behaviors.exit.value0.transition.value0)(pairs)(v1.value0.behaviors.exit.value0.attrs))();
              }
              ;
              if (v1.value0.behaviors.exit.value0.transition instanceof Nothing) {
                setAttrsExit1(v1.value0.behaviors.exit.value0.attrs)(v2.value0.exit)();
                remove1(v2.value0.exit)();
                return unit;
              }
              ;
              throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1514, column 7 - line 1522, column 20): " + [v1.value0.behaviors.exit.value0.transition.constructor.name]);
            }
            ;
            if (v1.value0.behaviors.exit instanceof Nothing) {
              remove1(v2.value0.exit)();
              return unit;
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1512, column 3 - line 1526, column 16): " + [v1.value0.behaviors.exit.constructor.name]);
          })();
          var enterElementsAndMaps = (function() {
            if (v1.value0.behaviors.enter instanceof Just) {
              var modifiedTemplate = function(datum2) {
                var v3 = v1.value0.template(datum2);
                if (v3 instanceof Node2) {
                  return new Node2({
                    name: v3.value0.name,
                    elemType: v3.value0.elemType,
                    behaviors: v3.value0.behaviors,
                    children: v3.value0.children,
                    attrs: append12(v3.value0.attrs)(v1.value0.behaviors.enter.value0.attrs)
                  });
                }
                ;
                return v3;
              };
              var rendered = renderTemplatesForPendingSelection(dictOrd)(modifiedTemplate)(v2.value0.enter)();
              (function() {
                if (v1.value0.behaviors.enter.value0.transition instanceof Just) {
                  var enterElements2 = map19(fst)(rendered);
                  var pendingData = (function() {
                    if (v2.value0.enter instanceof PendingSelection) {
                      return v2.value0.enter.value0.pendingData;
                    }
                    ;
                    throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1555, column 41 - line 1556, column 54): " + [v2.value0.enter.constructor.name]);
                  })();
                  var pairs = zipWith(Tuple.create)(enterElements2)(pendingData);
                  return liftEffect7(traverseWithIndex_2(function(index6) {
                    return function(v3) {
                      var finalAttrs = (function() {
                        var v4 = v1.value0.template(v3.value1);
                        if (v4 instanceof Node2) {
                          return v4.value0.attrs;
                        }
                        ;
                        return [];
                      })();
                      return applyTransitionToSingleElement(v1.value0.behaviors.enter.value0.transition.value0)(index6)(v3.value0)(v3.value1)(finalAttrs);
                    };
                  })(pairs))();
                }
                ;
                if (v1.value0.behaviors.enter.value0.transition instanceof Nothing) {
                  return unit;
                }
                ;
                throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1550, column 7 - line 1566, column 29): " + [v1.value0.behaviors.enter.value0.transition.constructor.name]);
              })();
              return rendered;
            }
            ;
            if (v1.value0.behaviors.enter instanceof Nothing) {
              return renderTemplatesForPendingSelection(dictOrd)(v1.value0.template)(v2.value0.enter)();
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1537, column 27 - line 1571, column 68): " + [v1.value0.behaviors.enter.constructor.name]);
          })();
          var enterElements = map19(fst)(enterElementsAndMaps);
          var enterChildMaps = map19(snd)(enterElementsAndMaps);
          var updateElements = (function() {
            if (v1.value0.behaviors.update instanceof Just) {
              if (v1.value0.behaviors.update.value0.transition instanceof Just) {
                var pairs = getBoundElementDatumPairs(v2.value0.update);
                liftEffect7(traverseWithIndex_2(function(index6) {
                  return function(v3) {
                    return applyTransitionToSingleElement(v1.value0.behaviors.update.value0.transition.value0)(index6)(v3.value0)(v3.value1)(v1.value0.behaviors.update.value0.attrs);
                  };
                })(pairs))();
                return getElementsFromBoundSelection(v2.value0.update);
              }
              ;
              if (v1.value0.behaviors.update.value0.transition instanceof Nothing) {
                setAttrs1(v1.value0.behaviors.update.value0.attrs)(v2.value0.update)();
                return renderTemplatesForBoundSelection1(v1.value0.template)(v2.value0.update)();
              }
              ;
              throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1580, column 7 - line 1596, column 71): " + [v1.value0.behaviors.update.value0.transition.constructor.name]);
            }
            ;
            if (v1.value0.behaviors.update instanceof Nothing) {
              return renderTemplatesForBoundSelection1(v1.value0.template)(v2.value0.update)();
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1577, column 21 - line 1599, column 67): " + [v1.value0.behaviors.update.constructor.name]);
          })();
          var allElements = append12(enterElements)(updateElements);
          var combinedChildMap = foldl2(union3)(empty2)(enterChildMaps);
          var doc2 = (function() {
            if (v2.value0.enter instanceof PendingSelection) {
              return v2.value0.enter.value0.document;
            }
            ;
            if (v2.value0.update instanceof BoundSelection) {
              return v2.value0.update.value0.document;
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1613, column 12 - line 1614, column 43): " + [v2.value0.update.constructor.name]);
          })();
          var allData = (function() {
            if (v2.value0.enter instanceof PendingSelection) {
              return v2.value0.enter.value0.pendingData;
            }
            ;
            return [];
          })();
          var updateData = (function() {
            if (v2.value0.update instanceof BoundSelection) {
              return v2.value0.update.value0.data;
            }
            ;
            return [];
          })();
          var boundSel = new BoundSelection({
            elements: allElements,
            data: append12(allData)(updateData),
            indices: new Just(range2(0)(length(allElements) - 1 | 0)),
            document: doc2
          });
          var selectionsMap = insert5(v1.value0.name)(boundSel)(combinedChildMap);
          var firstElement = (function() {
            var v3 = head(allElements);
            if (v3 instanceof Just) {
              return v3.value0;
            }
            ;
            if (v3 instanceof Nothing) {
              return createElementWithNS(Group.value)(doc2)();
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1638, column 19 - line 1640, column 45): " + [v3.constructor.name]);
          })();
          return new Tuple(firstElement, selectionsMap);
        };
      }
      ;
      if (v1 instanceof UpdateNestedJoin) {
        var innerData = join3(map19(v1.value0.decompose)(v1.value0.joinData));
        return function __do2() {
          var v2 = joinDataWithKey1(innerData)(jsonStringify_)(v1.value0.key)(v)();
          (function() {
            if (v1.value0.behaviors.exit instanceof Just) {
              if (v1.value0.behaviors.exit.value0.transition instanceof Just) {
                var pairs = getExitingElementDatumPairs(v2.value0.exit);
                return liftEffect7(applyExitTransitionToElements(v1.value0.behaviors.exit.value0.transition.value0)(pairs)(v1.value0.behaviors.exit.value0.attrs))();
              }
              ;
              if (v1.value0.behaviors.exit.value0.transition instanceof Nothing) {
                setAttrsExit1(v1.value0.behaviors.exit.value0.attrs)(v2.value0.exit)();
                remove1(v2.value0.exit)();
                return unit;
              }
              ;
              throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1691, column 7 - line 1699, column 20): " + [v1.value0.behaviors.exit.value0.transition.constructor.name]);
            }
            ;
            if (v1.value0.behaviors.exit instanceof Nothing) {
              remove1(v2.value0.exit)();
              return unit;
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1689, column 3 - line 1702, column 16): " + [v1.value0.behaviors.exit.constructor.name]);
          })();
          var enterElementsAndMaps = (function() {
            if (v1.value0.behaviors.enter instanceof Just) {
              var modifiedTemplate = function(datum2) {
                var v3 = v1.value0.template(datum2);
                if (v3 instanceof Node2) {
                  return new Node2({
                    name: v3.value0.name,
                    elemType: v3.value0.elemType,
                    behaviors: v3.value0.behaviors,
                    children: v3.value0.children,
                    attrs: append12(v3.value0.attrs)(v1.value0.behaviors.enter.value0.attrs)
                  });
                }
                ;
                return v3;
              };
              var rendered = renderTemplatesForPendingSelection(dictOrd)(modifiedTemplate)(v2.value0.enter)();
              (function() {
                if (v1.value0.behaviors.enter.value0.transition instanceof Just) {
                  var enterElements2 = map19(fst)(rendered);
                  var pendingData = (function() {
                    if (v2.value0.enter instanceof PendingSelection) {
                      return v2.value0.enter.value0.pendingData;
                    }
                    ;
                    throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1735, column 41 - line 1736, column 54): " + [v2.value0.enter.constructor.name]);
                  })();
                  var pairs = zipWith(Tuple.create)(enterElements2)(pendingData);
                  return liftEffect7(traverseWithIndex_2(function(index6) {
                    return function(v4) {
                      var finalAttrs = (function() {
                        var v5 = v1.value0.template(v4.value1);
                        if (v5 instanceof Node2) {
                          return v5.value0.attrs;
                        }
                        ;
                        return [];
                      })();
                      return applyTransitionToSingleElement(v1.value0.behaviors.enter.value0.transition.value0)(index6)(v4.value0)(v4.value1)(finalAttrs);
                    };
                  })(pairs))();
                }
                ;
                if (v1.value0.behaviors.enter.value0.transition instanceof Nothing) {
                  return unit;
                }
                ;
                throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1730, column 7 - line 1746, column 29): " + [v1.value0.behaviors.enter.value0.transition.constructor.name]);
              })();
              return rendered;
            }
            ;
            if (v1.value0.behaviors.enter instanceof Nothing) {
              return renderTemplatesForPendingSelection(dictOrd)(v1.value0.template)(v2.value0.enter)();
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1719, column 27 - line 1749, column 92): " + [v1.value0.behaviors.enter.constructor.name]);
          })();
          var updateElements = (function() {
            if (v1.value0.behaviors.update instanceof Just) {
              if (v1.value0.behaviors.update.value0.transition instanceof Just) {
                var pairs = getBoundElementDatumPairs(v2.value0.update);
                liftEffect7(traverseWithIndex_2(function(index6) {
                  return function(v4) {
                    return applyTransitionToSingleElement(v1.value0.behaviors.update.value0.transition.value0)(index6)(v4.value0)(v4.value1)(v1.value0.behaviors.update.value0.attrs);
                  };
                })(pairs))();
                return getElementsFromBoundSelection(v2.value0.update);
              }
              ;
              if (v1.value0.behaviors.update.value0.transition instanceof Nothing) {
                setAttrs1(v1.value0.behaviors.update.value0.attrs)(v2.value0.update)();
                return renderTemplatesForBoundSelection1(v1.value0.template)(v2.value0.update)();
              }
              ;
              throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1755, column 7 - line 1768, column 86): " + [v1.value0.behaviors.update.value0.transition.constructor.name]);
            }
            ;
            if (v1.value0.behaviors.update instanceof Nothing) {
              return renderTemplatesForBoundSelection1(v1.value0.template)(v2.value0.update)();
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1752, column 21 - line 1769, column 91): " + [v1.value0.behaviors.update.constructor.name]);
          })();
          var enterElements = map19(fst)(enterElementsAndMaps);
          var allElements = append12(enterElements)(updateElements);
          var enterChildMaps = map19(snd)(enterElementsAndMaps);
          var combinedChildMap = foldl2(union3)(empty2)(enterChildMaps);
          var doc2 = (function() {
            if (v2.value0.enter instanceof PendingSelection) {
              return v2.value0.enter.value0.document;
            }
            ;
            if (v2.value0.update instanceof BoundSelection) {
              return v2.value0.update.value0.document;
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1788, column 12 - line 1789, column 43): " + [v2.value0.update.constructor.name]);
          })();
          var boundSel = new BoundSelection({
            elements: allElements,
            data: innerData,
            indices: new Just(range2(0)(length(allElements) - 1 | 0)),
            document: doc2
          });
          var selectionsMap = insert5(v1.value0.name)(boundSel)(combinedChildMap);
          var firstElement = (function() {
            var v5 = head(allElements);
            if (v5 instanceof Just) {
              return v5.value0;
            }
            ;
            if (v5 instanceof Nothing) {
              return createElementWithNS(Group.value)(doc2)();
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1803, column 19 - line 1805, column 45): " + [v5.constructor.name]);
          })();
          return new Tuple(firstElement, selectionsMap);
        };
      }
      ;
      if (v1 instanceof ConditionalRender) {
        var doc = (function() {
          if (v instanceof EmptySelection) {
            return v.value0.document;
          }
          ;
          if (v instanceof EmptySelection) {
            return v.value0.document;
          }
          ;
          throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1819, column 29 - line 1819, column 76): " + [v.constructor.name]);
        })();
        return function __do2() {
          var dummyElement = createElementWithNS(Group.value)(doc)();
          return new Tuple(dummyElement, empty2);
        };
      }
      ;
      if (v1 instanceof LocalCoordSpace) {
        return renderNodeHelper(dictOrd)(v)(v1.value0.child);
      }
      ;
      throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1339, column 1 - line 1344, column 74): " + [v.constructor.name, v1.constructor.name]);
    };
  };
};
var renderNestedTemplatesForPendingSelection = function(dictOrd) {
  return function(decomposer) {
    return function(templateFn) {
      return function(wrapperType) {
        return function(pendingSel) {
          var v = (function() {
            if (pendingSel instanceof PendingSelection) {
              return pendingSel.value0;
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1851, column 68 - line 1852, column 34): " + [pendingSel.constructor.name]);
          })();
          return traverseWithIndex2(function(idx) {
            return function(outerDatum) {
              var parentIdx = mod2(idx)(length(v.parentElements));
              var v1 = index(v.parentElements)(parentIdx);
              if (v1 instanceof Nothing) {
                return unsafeCrashWith("renderNestedTemplatesForPendingSelection: no parent elements");
              }
              ;
              if (v1 instanceof Just) {
                return function __do2() {
                  var wrapperElement = createElementWithNS(wrapperType)(v.document)();
                  var wrapperNode = toNode2(wrapperElement);
                  var parentNode3 = toNode2(v1.value0);
                  appendChild(wrapperNode)(parentNode3)();
                  var innerDataArray = decomposer(outerDatum);
                  var innerMaps = traverseWithIndex2(function(innerIdx) {
                    return function(innerDatumErased) {
                      var tree = templateFn(innerDatumErased);
                      var singleParentSel = new EmptySelection({
                        parentElements: [wrapperElement],
                        document: v.document
                      });
                      return function __do3() {
                        var v2 = renderNodeHelperWithDatum(dictOrd)(singleParentSel)(tree)(new Just(innerDatumErased))(innerIdx)();
                        return v2.value1;
                      };
                    };
                  })(innerDataArray)();
                  var combinedInnerMap = foldl2(union3)(empty2)(innerMaps);
                  return new Tuple(wrapperElement, combinedInnerMap);
                };
              }
              ;
              throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 1857, column 9 - line 1889, column 57): " + [v1.constructor.name]);
            };
          })(v.pendingData);
        };
      };
    };
  };
};
var renderTree2 = function(dictOrd) {
  var renderNodeHelper1 = renderNodeHelper(dictOrd);
  return function(parent2) {
    return function(tree) {
      return function __do2() {
        var v = renderNodeHelper1(parent2)(tree)();
        return v.value1;
      };
    };
  };
};
var appendChildInheriting = function(dictMonadEffect) {
  var liftEffect12 = liftEffect(dictMonadEffect);
  return function(elemType) {
    return function(attrs) {
      return function(v) {
        return liftEffect12((function() {
          var v1 = (function() {
            if (v instanceof BoundSelection) {
              return v.value0;
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 516, column 82 - line 517, column 28): " + [v.constructor.name]);
          })();
          return function __do2() {
            var childElements = traverseWithIndex2(function(idx) {
              return function(v2) {
                return function __do3() {
                  var child = createElementWithNS(elemType)(v1.document)();
                  setElementData_(v2.value1)(child)();
                  applyAttributes(child)(v2.value1)(idx)(attrs)();
                  var childNode = toNode2(child);
                  var parentNode3 = toNode2(v2.value0);
                  appendChild(childNode)(parentNode3)();
                  return child;
                };
              };
            })(zipWith(Tuple.create)(v1.elements)(v1.data))();
            return new BoundSelection({
              elements: childElements,
              data: v1.data,
              indices: Nothing.value,
              document: v1.document
            });
          };
        })());
      };
    };
  };
};
var appendChild2 = function(dictMonadEffect) {
  var liftEffect12 = liftEffect(dictMonadEffect);
  return function(elemType) {
    return function(attrs) {
      return function(v) {
        return liftEffect12((function() {
          var v1 = (function() {
            if (v instanceof EmptySelection) {
              return v.value0;
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 423, column 55 - line 424, column 28): " + [v.constructor.name]);
          })();
          return function __do2() {
            var elements = traverse2(function(parent2) {
              return function __do3() {
                var element3 = createElementWithNS(elemType)(v1.document)();
                applyAttributes(element3)(unit)(0)(attrs)();
                var elementNode = toNode2(element3);
                var parentNode3 = toNode2(parent2);
                appendChild(elementNode)(parentNode3)();
                return element3;
              };
            })(v1.parentElements)();
            return new EmptySelection({
              parentElements: elements,
              document: v1.document
            });
          };
        })());
      };
    };
  };
};
var append7 = function(dictMonadEffect) {
  var liftEffect12 = liftEffect(dictMonadEffect);
  return function(elemType) {
    return function(attrs) {
      return function(v) {
        return liftEffect12((function() {
          var v1 = (function() {
            if (v instanceof PendingSelection) {
              return v.value0;
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 228, column 77 - line 229, column 30): " + [v.constructor.name]);
          })();
          var parent2 = (function() {
            var v2 = head(v1.parentElements);
            if (v2 instanceof Just) {
              return v2.value0;
            }
            ;
            if (v2 instanceof Nothing) {
              return unsafeIndex3(v1.parentElements)(0);
            }
            ;
            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 234, column 14 - line 236, column 68): " + [v2.constructor.name]);
          })();
          return function __do2() {
            var elements = traverseWithIndex2(function(arrayIndex) {
              return function(datum2) {
                var logicalIndex = (function() {
                  if (v1.indices instanceof Just) {
                    return unsafeIndex3(v1.indices.value0)(arrayIndex);
                  }
                  ;
                  if (v1.indices instanceof Nothing) {
                    return arrayIndex;
                  }
                  ;
                  throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 241, column 22 - line 243, column 30): " + [v1.indices.constructor.name]);
                })();
                return function __do3() {
                  var element3 = createElementWithNS(elemType)(v1.document)();
                  applyAttributes(element3)(datum2)(logicalIndex)(attrs)();
                  setElementData_(datum2)(element3)();
                  var elementNode = toNode2(element3);
                  var parentNode3 = toNode2(parent2);
                  appendChild(elementNode)(parentNode3)();
                  return element3;
                };
              };
            })(v1.pendingData)();
            return new BoundSelection({
              elements,
              data: v1.pendingData,
              indices: v1.indices,
              document: v1.document
            });
          };
        })());
      };
    };
  };
};
var append32 = /* @__PURE__ */ append7(monadEffectEffect);
var appendData = function(dictMonadEffect) {
  var liftEffect12 = liftEffect(dictMonadEffect);
  return function(dictFoldable) {
    var fromFoldable3 = fromFoldable(dictFoldable);
    return function(elemType) {
      return function(foldableData) {
        return function(attrs) {
          return function(emptySelection) {
            return liftEffect12((function() {
              var v = (function() {
                if (emptySelection instanceof EmptySelection) {
                  return emptySelection.value0;
                }
                ;
                throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 832, column 55 - line 833, column 28): " + [emptySelection.constructor.name]);
              })();
              var dataArray = fromFoldable3(foldableData);
              var pendingSelection = new PendingSelection({
                parentElements: v.parentElements,
                pendingData: dataArray,
                indices: new Just(range2(0)(length(dataArray) - 1 | 0)),
                document: v.document
              });
              return append32(elemType)(attrs)(pendingSelection);
            })());
          };
        };
      };
    };
  };
};
var renderData = function(dictMonadEffect) {
  var Monad0 = dictMonadEffect.Monad0();
  var Bind1 = Monad0.Bind1();
  var bind16 = bind(Bind1);
  var joinData22 = joinData(dictMonadEffect);
  var append42 = append7(dictMonadEffect);
  var pure14 = pure(Monad0.Applicative0());
  var applyPerDatumAttrs1 = applyPerDatumAttrs(dictMonadEffect);
  var discard24 = discard5(Bind1);
  var remove22 = remove2(dictMonadEffect);
  var merge1 = merge(dictMonadEffect);
  return function(dictFoldable) {
    var joinData3 = joinData22(dictFoldable);
    return function(dictOrd) {
      var joinData4 = joinData3(dictOrd);
      return function(elemType) {
        return function(foldableData) {
          return function(selector) {
            return function(emptySelection) {
              return function(enterAttrs) {
                return function(updateAttrs) {
                  return function(exitAttrs) {
                    return bind16(joinData4(foldableData)(selector)(emptySelection))(function(v) {
                      return bind16(bind16(append42(elemType)([])(v.value0.enter))(function(bound) {
                        if (enterAttrs instanceof Nothing) {
                          return pure14(bound);
                        }
                        ;
                        if (enterAttrs instanceof Just) {
                          return applyPerDatumAttrs1(enterAttrs.value0)(bound);
                        }
                        ;
                        throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 785, column 5 - line 787, column 55): " + [enterAttrs.constructor.name]);
                      }))(function(enterBound) {
                        return bind16((function() {
                          if (updateAttrs instanceof Nothing) {
                            return pure14(v.value0.update);
                          }
                          ;
                          if (updateAttrs instanceof Just) {
                            return applyPerDatumAttrs1(updateAttrs.value0)(v.value0.update);
                          }
                          ;
                          throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 790, column 18 - line 792, column 54): " + [updateAttrs.constructor.name]);
                        })())(function(updateBound) {
                          return discard24((function() {
                            if (exitAttrs instanceof Nothing) {
                              return remove22(v.value0.exit);
                            }
                            ;
                            if (exitAttrs instanceof Just) {
                              return bind16(applyPerDatumAttrs1(exitAttrs.value0)(v.value0.exit))(function() {
                                return remove22(v.value0.exit);
                              });
                            }
                            ;
                            throw new Error("Failed pattern match at PSD3.Internal.Selection.Operations (line 795, column 3 - line 799, column 18): " + [exitAttrs.constructor.name]);
                          })())(function() {
                            return merge1(enterBound)(updateBound);
                          });
                        });
                      });
                    });
                  };
                };
              };
            };
          };
        };
      };
    };
  };
};

// output/PSD3.Interpreter.D3/index.js
var select7 = /* @__PURE__ */ select6(monadEffectEffect);
var selectElement3 = /* @__PURE__ */ selectElement2(monadEffectEffect);
var selectAll2 = /* @__PURE__ */ selectAll(monadEffectEffect);
var selectAllWithData2 = /* @__PURE__ */ selectAllWithData(monadEffectEffect);
var renderData2 = /* @__PURE__ */ renderData(monadEffectEffect);
var appendData2 = /* @__PURE__ */ appendData(monadEffectEffect);
var joinData2 = /* @__PURE__ */ joinData(monadEffectEffect);
var joinDataWithKey2 = /* @__PURE__ */ joinDataWithKey(monadEffectEffect);
var append8 = /* @__PURE__ */ append7(monadEffectEffect);
var setAttrs2 = /* @__PURE__ */ setAttrs(monadEffectEffect);
var setAttrsExit2 = /* @__PURE__ */ setAttrsExit(monadEffectEffect);
var remove4 = /* @__PURE__ */ remove2(monadEffectEffect);
var clear4 = /* @__PURE__ */ clear3(monadEffectEffect);
var merge2 = /* @__PURE__ */ merge(monadEffectEffect);
var appendChild3 = /* @__PURE__ */ appendChild2(monadEffectEffect);
var appendChildInheriting2 = /* @__PURE__ */ appendChildInheriting(monadEffectEffect);
var map20 = /* @__PURE__ */ map(functorMap);
var D3v2Selection_ = function(x4) {
  return x4;
};
var monadD3v2M = monadEffect;
var selectionMD3v2Selection_D = {
  select: function(selector) {
    return function __do2() {
      var sel = select7(selector)();
      return sel;
    };
  },
  selectElement: function(element3) {
    return function __do2() {
      var sel = selectElement3(element3)();
      return sel;
    };
  },
  selectAll: function(selector) {
    return function(v) {
      return function __do2() {
        var result = selectAll2(selector)(v)();
        return result;
      };
    };
  },
  openSelection: function(v) {
    return function(selector) {
      return function __do2() {
        var result = selectAll2(selector)(v)();
        return result;
      };
    };
  },
  selectAllWithData: function(selector) {
    return function(v) {
      return function __do2() {
        var result = selectAllWithData2(selector)(v)();
        return result;
      };
    };
  },
  renderData: function(dictFoldable) {
    var renderData1 = renderData2(dictFoldable);
    return function(dictOrd) {
      var renderData22 = renderData1(dictOrd);
      return function(elemType) {
        return function(foldableData) {
          return function(selector) {
            return function(v) {
              return function(enterAttrs) {
                return function(updateAttrs) {
                  return function(exitAttrs) {
                    return function __do2() {
                      var result = renderData22(elemType)(foldableData)(selector)(v)(enterAttrs)(updateAttrs)(exitAttrs)();
                      return result;
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  },
  appendData: function(dictFoldable) {
    var appendData1 = appendData2(dictFoldable);
    return function(elemType) {
      return function(foldableData) {
        return function(attrs) {
          return function(v) {
            return function __do2() {
              var result = appendData1(elemType)(foldableData)(attrs)(v)();
              return result;
            };
          };
        };
      };
    };
  },
  joinData: function(dictFoldable) {
    var joinData12 = joinData2(dictFoldable);
    return function(dictOrd) {
      var joinData22 = joinData12(dictOrd);
      return function(foldableData) {
        return function(selector) {
          return function(v) {
            return function __do2() {
              var v1 = joinData22(foldableData)(selector)(v)();
              return new JoinResult({
                enter: v1.value0.enter,
                update: v1.value0.update,
                exit: v1.value0.exit
              });
            };
          };
        };
      };
    };
  },
  joinDataWithKey: function(dictFoldable) {
    var joinDataWithKey12 = joinDataWithKey2(dictFoldable);
    return function(dictOrd) {
      var joinDataWithKey22 = joinDataWithKey12(dictOrd.Eq0());
      return function(foldableData) {
        return function(keyFn) {
          return function(selector) {
            return function(v) {
              return function __do2() {
                var v1 = joinDataWithKey22(foldableData)(keyFn)(selector)(v)();
                return new JoinResult({
                  enter: v1.value0.enter,
                  update: v1.value0.update,
                  exit: v1.value0.exit
                });
              };
            };
          };
        };
      };
    };
  },
  updateJoin: function(dictFoldable) {
    var joinDataWithKey12 = joinDataWithKey2(dictFoldable);
    return function(dictOrd) {
      var joinDataWithKey22 = joinDataWithKey12(dictOrd.Eq0());
      return function(v) {
        return function(_elemType) {
          return function(foldableData) {
            return function(keyFn) {
              return function(selector) {
                return function __do2() {
                  var v1 = joinDataWithKey22(foldableData)(keyFn)(selector)(v)();
                  return new JoinResult({
                    enter: v1.value0.enter,
                    update: v1.value0.update,
                    exit: v1.value0.exit
                  });
                };
              };
            };
          };
        };
      };
    };
  },
  append: function(elemType) {
    return function(attrs) {
      return function(v) {
        return function __do2() {
          var result = append8(elemType)(attrs)(v)();
          return result;
        };
      };
    };
  },
  setAttrs: function(attrs) {
    return function(v) {
      return function __do2() {
        var result = setAttrs2(attrs)(v)();
        return result;
      };
    };
  },
  setAttrsExit: function(attrs) {
    return function(v) {
      return function __do2() {
        var result = setAttrsExit2(attrs)(v)();
        return result;
      };
    };
  },
  remove: function(v) {
    return remove4(v);
  },
  clear: function(selector) {
    return clear4(selector);
  },
  merge: function(v) {
    return function(v1) {
      return function __do2() {
        var result = merge2(v)(v1)();
        return result;
      };
    };
  },
  appendChild: function(elemType) {
    return function(attrs) {
      return function(v) {
        return function __do2() {
          var result = appendChild3(elemType)(attrs)(v)();
          return result;
        };
      };
    };
  },
  appendChildInheriting: function(elemType) {
    return function(attrs) {
      return function(v) {
        return function __do2() {
          var result = appendChildInheriting2(elemType)(attrs)(v)();
          return result;
        };
      };
    };
  },
  on: function(behavior) {
    return function(v) {
      return function __do2() {
        var result = on2(behavior)(v)();
        return result;
      };
    };
  },
  renderTree: function(dictOrd) {
    var renderTree4 = renderTree2(dictOrd);
    return function(v) {
      return function(tree) {
        return function __do2() {
          var selectionsMap = renderTree4(v)(tree)();
          return map20(D3v2Selection_)(selectionsMap);
        };
      };
    };
  },
  Monad0: function() {
    return monadD3v2M;
  }
};
var bindD3v2M = bindEffect;
var applicativeD3v2M = applicativeEffect;
var runD3v2M = function(v) {
  return v;
};

// output/Web.WebSocket/foreign.js
var create5 = (url2) => () => {
  return new WebSocket(url2);
};
var onOpen = (ws) => (handler3) => () => {
  ws.onopen = () => handler3();
};
var onCloseImpl = (ws, handler3) => () => {
  ws.onclose = (event) => {
    const closeEvent = {
      code: event.code,
      reason: event.reason,
      wasClean: event.wasClean
    };
    handler3(closeEvent)();
  };
};
var onMessageImpl = (ws, handler3) => () => {
  ws.onmessage = (event) => handler3(event)();
};
var onErrorImpl = (ws, handler3) => () => {
  ws.onerror = () => handler3();
};
var close2 = (ws) => () => {
  ws.close();
};
var getMessageData = (event) => {
  const data = event.data;
  if (typeof data === "string") {
    return data;
  } else if (data instanceof ArrayBuffer) {
    const decoder = new TextDecoder();
    return decoder.decode(data);
  }
  return String(data);
};

// output/Web.WebSocket/index.js
var onMessage = function(ws) {
  return function(handler3) {
    return onMessageImpl(ws, handler3);
  };
};
var onError = function(ws) {
  return function(handler3) {
    return onErrorImpl(ws, handler3);
  };
};
var onClose = function(ws) {
  return function(handler3) {
    return onCloseImpl(ws, handler3);
  };
};

// output/Demo.HalogenPSD3Chart/index.js
var show4 = /* @__PURE__ */ show(showInt);
var bind6 = /* @__PURE__ */ bind(bindD3v2M);
var select8 = /* @__PURE__ */ select5(selectionMD3v2Selection_D);
var map21 = /* @__PURE__ */ map(functorMaybe);
var max6 = /* @__PURE__ */ max(ordInt);
var show12 = /* @__PURE__ */ show(showNumber);
var attr4 = /* @__PURE__ */ attr3(toAttributeValueNumber);
var num2 = /* @__PURE__ */ num(numExprEvalD);
var transform3 = /* @__PURE__ */ transform(toAttributeValueString);
var text7 = /* @__PURE__ */ text6(stringExprEvalD);
var x3 = /* @__PURE__ */ x(toAttributeValueNumber);
var y3 = /* @__PURE__ */ y(toAttributeValueNumber);
var fill2 = /* @__PURE__ */ fill(toAttributeValueString);
var map110 = /* @__PURE__ */ map(functorArray);
var x12 = /* @__PURE__ */ x1(toAttributeValueNumber);
var y12 = /* @__PURE__ */ y1(toAttributeValueNumber);
var x22 = /* @__PURE__ */ x2(toAttributeValueNumber);
var y22 = /* @__PURE__ */ y2(toAttributeValueNumber);
var stroke2 = /* @__PURE__ */ stroke(toAttributeValueString);
var strokeWidth2 = /* @__PURE__ */ strokeWidth(toAttributeValueNumber);
var attr1 = /* @__PURE__ */ attr3(toAttributeValueString);
var textAnchor2 = /* @__PURE__ */ textAnchor(toAttributeValueString);
var textContent3 = /* @__PURE__ */ textContent2(toAttributeValueString);
var discard6 = /* @__PURE__ */ discard(discardUnit);
var discard12 = /* @__PURE__ */ discard6(bindD3v2M);
var clear5 = /* @__PURE__ */ clear2(selectionMD3v2Selection_D);
var renderTree3 = /* @__PURE__ */ renderTree(selectionMD3v2Selection_D)(ordUnit);
var pure10 = /* @__PURE__ */ pure(applicativeD3v2M);
var discard23 = /* @__PURE__ */ discard6(bindHalogenM);
var bind15 = /* @__PURE__ */ bind(bindHalogenM);
var get4 = /* @__PURE__ */ get(monadStateHalogenM);
var modify_3 = /* @__PURE__ */ modify_(monadStateHalogenM);
var pure13 = /* @__PURE__ */ pure(applicativeEffect);
var pure23 = /* @__PURE__ */ pure(applicativeHalogenM);
var Initialize2 = /* @__PURE__ */ (function() {
  function Initialize3() {
  }
  ;
  Initialize3.value = new Initialize3();
  return Initialize3;
})();
var Connect = /* @__PURE__ */ (function() {
  function Connect2() {
  }
  ;
  Connect2.value = new Connect2();
  return Connect2;
})();
var Disconnect = /* @__PURE__ */ (function() {
  function Disconnect2() {
  }
  ;
  Disconnect2.value = new Disconnect2();
  return Disconnect2;
})();
var ReceiveData = /* @__PURE__ */ (function() {
  function ReceiveData2(value0) {
    this.value0 = value0;
  }
  ;
  ReceiveData2.create = function(value0) {
    return new ReceiveData2(value0);
  };
  return ReceiveData2;
})();
var render = function(state3) {
  var statusStyle = function(v) {
    if (v === "Connected") {
      return "background: #065f46; color: #6ee7b7;";
    }
    ;
    if (v === "Connecting") {
      return "background: #78350f; color: #fcd34d;";
    }
    ;
    return "background: #7f1d1d; color: #fca5a5;";
  };
  return div2([style("font-family: system-ui; padding: 20px; background: #1a1a2e; color: #eee; min-height: 100vh;")])([h1([style("color: #7c3aed; margin-bottom: 5px;")])([text5("PSD3 Real-time Chart")]), p([style("color: #888; margin-top: 0;")])([text5("Halogen + PSD3 + Python WebSocket Streaming")]), div2([style("margin: 20px 0;")])([button([onClick(function(v) {
    return Connect.value;
  }), style("padding: 10px 20px; margin-right: 10px; background: #7c3aed; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: bold;"), disabled10(state3.status === "Connected")])([text5("Connect")]), button([onClick(function(v) {
    return Disconnect.value;
  }), style("padding: 10px 20px; background: #374151; color: white; border: none; border-radius: 6px; cursor: pointer;"), disabled10(state3.status !== "Connected")])([text5("Disconnect")]), span3([style("margin-left: 20px; padding: 8px 15px; border-radius: 6px; " + statusStyle(state3.status))])([text5(state3.status)])]), div2([style("margin: 15px 0; color: #6ee7b7;")])([text5("Data points: " + (show4(length(state3.dataBuffer)) + (" / " + show4(state3.maxPoints))))]), div2([id2("psd3-chart"), style("background: #0d1117; border-radius: 8px; padding: 10px; margin-top: 20px;")])([])]);
};
var parseDataMessage = function($94) {
  return toMaybe(parseDataMessageImpl($94));
};
var maxBufferSize = 100;
var margin = {
  top: 40,
  right: 30,
  bottom: 50,
  left: 60
};
var chartWidth = 700;
var chartHeight = 350;
var renderChart = function(dataPoints) {
  return runD3v2M(bind6(select8("#psd3-chart"))(function(container) {
    var plotWidth = chartWidth - margin.left - margin.right;
    var plotHeight = chartHeight - margin.top - margin.bottom;
    var scaleY = function(value12) {
      var normalized = (value12 + 1.5) / 3;
      return plotHeight - normalized * plotHeight;
    };
    var minTick = fromMaybe(0)(map21(function(v) {
      return v.tick;
    })(head(dataPoints)));
    var maxTick = fromMaybe(100)(map21(function(v) {
      return v.tick;
    })(last(dataPoints)));
    var tickRange = max6(1)(maxTick - minTick | 0);
    var scaleX = function(tick) {
      var normalized = toNumber(tick - minTick | 0) / toNumber(tickRange);
      return normalized * plotWidth;
    };
    var gridValues = [-1, -0.5, 0, 0.5, 1];
    var buildPathSecondary = function(pts) {
      var v = uncons(pts);
      if (v instanceof Nothing) {
        return "";
      }
      ;
      if (v instanceof Just) {
        return "M " + (show12(scaleX(v.value0.head.tick)) + (" " + (show12(scaleY(v.value0.head.secondary)) + foldl2(function(acc) {
          return function(pt) {
            return acc + (" L " + (show12(scaleX(pt.tick)) + (" " + show12(scaleY(pt.secondary)))));
          };
        })("")(v.value0.tail))));
      }
      ;
      throw new Error("Failed pattern match at Demo.HalogenPSD3Chart (line 226, column 32 - line 230, column 121): " + [v.constructor.name]);
    };
    var pathSecondary = buildPathSecondary(dataPoints);
    var buildPath = function(pts) {
      var v = uncons(pts);
      if (v instanceof Nothing) {
        return "";
      }
      ;
      if (v instanceof Just) {
        return "M " + (show12(scaleX(v.value0.head.tick)) + (" " + (show12(scaleY(v.value0.head.primary)) + foldl2(function(acc) {
          return function(pt) {
            return acc + (" L " + (show12(scaleX(pt.tick)) + (" " + show12(scaleY(pt.primary)))));
          };
        })("")(v.value0.tail))));
      }
      ;
      throw new Error("Failed pattern match at Demo.HalogenPSD3Chart (line 219, column 23 - line 223, column 119): " + [v.constructor.name]);
    };
    var pathPrimary = buildPath(dataPoints);
    var tree = withChild(named(SVG.value)("svg")([attr4("width")(num2(chartWidth)), attr4("height")(num2(chartHeight)), viewBox(0)(0)(chartWidth)(chartHeight)]))(withChildren(named(Group.value)("chart")([transform3(text7("translate(" + (show12(margin.left) + ("," + (show12(margin.top) + ")")))))]))([elem2(Rect.value)([x3(num2(0)), y3(num2(0)), attr4("width")(num2(plotWidth)), attr4("height")(num2(plotHeight)), fill2(text7("#161b22"))]), withChildren(named(Group.value)("grid")([]))(map110(function(v) {
      return elem2(Line.value)([x12(num2(0)), y12(num2(scaleY(v))), x22(num2(plotWidth)), y22(num2(scaleY(v))), stroke2(text7("#30363d")), strokeWidth2(num2(1))]);
    })(gridValues)), elem2(Line.value)([x12(num2(0)), y12(num2(scaleY(0))), x22(num2(plotWidth)), y22(num2(scaleY(0))), stroke2(text7("#484f58")), strokeWidth2(num2(2))]), elem2(Path.value)([attr1("d")(text7(pathSecondary)), fill2(text7("none")), stroke2(text7("#22d3ee")), strokeWidth2(num2(2)), attr4("opacity")(num2(0.7))]), elem2(Path.value)([attr1("d")(text7(pathPrimary)), fill2(text7("none")), stroke2(text7("#a855f7")), strokeWidth2(num2(2.5))]), withChildren(named(Group.value)("y-labels")([]))(map110(function(v) {
      return elem2(Text2.value)([x3(num2(-10)), y3(num2(scaleY(v) + 4)), textAnchor2(text7("end")), fill2(text7("#8b949e")), attr4("font-size")(num2(11)), textContent3(text7(show12(v)))]);
    })(gridValues)), elem2(Text2.value)([x3(num2(plotWidth / 2)), y3(num2(-15)), textAnchor2(text7("middle")), fill2(text7("#e6edf3")), attr4("font-size")(num2(14)), attr1("font-weight")(text7("bold")), textContent3(text7("Real-time Streaming Data"))]), withChildren(named(Group.value)("legend")([transform3(text7("translate(" + (show12(plotWidth - 120) + ", 15)")))]))([elem2(Line.value)([x12(num2(0)), y12(num2(0)), x22(num2(20)), y22(num2(0)), stroke2(text7("#a855f7")), strokeWidth2(num2(2.5))]), elem2(Text2.value)([x3(num2(25)), y3(num2(4)), fill2(text7("#8b949e")), attr4("font-size")(num2(11)), textContent3(text7("Primary"))]), elem2(Line.value)([x12(num2(0)), y12(num2(18)), x22(num2(20)), y22(num2(18)), stroke2(text7("#22d3ee")), strokeWidth2(num2(2))]), elem2(Text2.value)([x3(num2(25)), y3(num2(22)), fill2(text7("#8b949e")), attr4("font-size")(num2(11)), textContent3(text7("Secondary"))])])]));
    return discard12(clear5("#psd3-chart"))(function() {
      return bind6(renderTree3(container)(tree))(function() {
        return pure10(unit);
      });
    });
  }));
};
var handleAction = function(dictMonadAff) {
  var liftEffect8 = liftEffect(monadEffectHalogenM(dictMonadAff.MonadEffect0()));
  return function(v) {
    if (v instanceof Initialize2) {
      return discard23(liftEffect8(log2("[PSD3] Component initialized")))(function() {
        return bind15(get4)(function(state3) {
          return liftEffect8(renderChart(state3.dataBuffer));
        });
      });
    }
    ;
    if (v instanceof Connect) {
      return discard23(modify_3(function(v1) {
        var $80 = {};
        for (var $81 in v1) {
          if ({}.hasOwnProperty.call(v1, $81)) {
            $80[$81] = v1[$81];
          }
          ;
        }
        ;
        $80.status = "Connecting";
        return $80;
      }))(function() {
        return bind15(liftEffect8($$new([])))(function(dataRef) {
          return bind15(liftEffect8(create5("ws://localhost:8766")))(function(ws) {
            return discard23(liftEffect8(onOpen(ws)(log2("[PSD3] WebSocket connected"))))(function() {
              return discard23(liftEffect8(onMessage(ws)(function(event) {
                var msg = getMessageData(event);
                var v1 = parseDataMessage(msg);
                if (v1 instanceof Just) {
                  return function __do2() {
                    var currentData = read(dataRef)();
                    var newData = takeEnd(maxBufferSize)(snoc(currentData)(v1.value0));
                    write(newData)(dataRef)();
                    return renderChart(newData)();
                  };
                }
                ;
                if (v1 instanceof Nothing) {
                  return pure13(unit);
                }
                ;
                throw new Error("Failed pattern match at Demo.HalogenPSD3Chart (line 165, column 7 - line 173, column 29): " + [v1.constructor.name]);
              })))(function() {
                return discard23(liftEffect8(onClose(ws)(function(v1) {
                  return log2("[PSD3] WebSocket closed");
                })))(function() {
                  return discard23(liftEffect8(onError(ws)(log2("[PSD3] WebSocket error"))))(function() {
                    return modify_3(function(v1) {
                      var $85 = {};
                      for (var $86 in v1) {
                        if ({}.hasOwnProperty.call(v1, $86)) {
                          $85[$86] = v1[$86];
                        }
                        ;
                      }
                      ;
                      $85.ws = new Just(ws);
                      $85.status = "Connected";
                      return $85;
                    });
                  });
                });
              });
            });
          });
        });
      });
    }
    ;
    if (v instanceof Disconnect) {
      return bind15(get4)(function(state3) {
        return discard23((function() {
          if (state3.ws instanceof Just) {
            return liftEffect8(close2(state3.ws.value0));
          }
          ;
          if (state3.ws instanceof Nothing) {
            return pure23(unit);
          }
          ;
          throw new Error("Failed pattern match at Demo.HalogenPSD3Chart (line 185, column 5 - line 187, column 27): " + [state3.ws.constructor.name]);
        })())(function() {
          return modify_3(function(v1) {
            var $90 = {};
            for (var $91 in v1) {
              if ({}.hasOwnProperty.call(v1, $91)) {
                $90[$91] = v1[$91];
              }
              ;
            }
            ;
            $90.ws = Nothing.value;
            $90.status = "Disconnected";
            $90.dataBuffer = [];
            return $90;
          });
        });
      });
    }
    ;
    if (v instanceof ReceiveData) {
      return pure23(unit);
    }
    ;
    throw new Error("Failed pattern match at Demo.HalogenPSD3Chart (line 145, column 16 - line 190, column 29): " + [v.constructor.name]);
  };
};
var component = function(dictMonadAff) {
  return mkComponent({
    initialState: function(v) {
      return {
        ws: Nothing.value,
        dataBuffer: [],
        status: "Disconnected",
        maxPoints: maxBufferSize
      };
    },
    render,
    "eval": mkEval({
      handleQuery: defaultEval.handleQuery,
      receive: defaultEval.receive,
      finalize: defaultEval.finalize,
      handleAction: handleAction(dictMonadAff),
      initialize: new Just(Initialize2.value)
    })
  });
};
var component1 = /* @__PURE__ */ component(monadAffAff);
var main2 = /* @__PURE__ */ runHalogenAff(/* @__PURE__ */ bind(bindAff)(awaitBody)(function(body2) {
  return runUI2(component1)(unit)(body2);
}));
export {
  Connect,
  Disconnect,
  Initialize2 as Initialize,
  ReceiveData,
  chartHeight,
  chartWidth,
  component,
  handleAction,
  main2 as main,
  margin,
  maxBufferSize,
  parseDataMessage,
  parseDataMessageImpl,
  render,
  renderChart
};
