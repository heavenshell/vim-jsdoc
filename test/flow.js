// @flow
function foo(arg1 :string, arg2: number): string {
  return ''
}

interface Foo {
  foo: string
}

type Bar = {
  bar: number
}

class FooBar {
  props: Bar

  foo (arg1: string, arg2: any): void {
  }

  bar (arg1: number, arg2: Foo): any {
    return
  }
}
