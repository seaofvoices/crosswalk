type Expect = {
	to: Expect,
	be: Expect,
	been: Expect,
	have: Expect,
	was: Expect,
	at: Expect,
	never: Expect,
	equal: (value: any) -> (),
	ok: () -> (),
	throw: (string?) -> (),
	a: (typeName: string) -> (),
	an: (typeName: string) -> (),
	near: (value:number, limit: number?) -> (),
}

declare function expect(value: any): Expect

declare function it(name: string, callback: () -> ())
declare function itSKIP(name: string, callback: () -> ())
declare function describe(name: string, callback: () -> ())
declare function SKIP()

declare function beforeEach(callback: () -> ())
declare function beforeAll(callback: () -> ())
declare function afterEach(callback: () -> ())
declare function afterAll(callback: () -> ())
