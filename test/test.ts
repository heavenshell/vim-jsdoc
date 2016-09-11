function foo(foo: string = 'foo', bar: number = 1): string {
  return 'foo'
}

function bar() : any {
}

function _baz()  :number{
  return 1
}

function union(): number | string {
  return 'foo'
}

interface IFoo {
}

class Foo {
}

class Bar extends Foo implements IFoo {
  constructor(private arg1: string, public arg2: string) {
    super()
  }
  private foo(arg1: string, arg2: number = 0): void {
  }
  public _bar(): void {
  }
}

class Baz extends Foo implements IFoo {
}

function ifoo(): IFoo {
  return new Bar('foo', 'bar')
}

function list(args: Array<Bar>): void {
}
