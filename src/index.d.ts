declare namespace SwiftPacket {
	type Results<R extends unknown[]> = R extends [] ? void : R extends [infer T] ? T : LuaTuple<R>;

	type OptionalKeys<T> = { [K in keyof T]-?: undefined extends T[K] ? K : never }[keyof T];

	type Shape<T> = { [K in Exclude<keyof T, OptionalKeys<T>>]: T[K] } & { [K in OptionalKeys<T>]?: T[K] };

	type Flatten<T> = { [K in keyof T]: T[K] };

	interface Options {
		Logging?: boolean;
		IncomingBytesPerSecond?: number;
		UnreliableByteLimit?: number;
	}

	interface Connection {
		readonly Connected: boolean;
		Disconnect(): void;
	}

	interface Signal<A extends unknown[]> {
		Connect(callback: (...args: A) => void): Connection;
		Once(callback: (...args: A) => void): Connection;
		Wait(): LuaTuple<A>;
		DisconnectAll(): void;
	}

	interface Event<A extends unknown[]> {
		readonly Name: string;
		readonly OnServerEvent: Signal<[player: Player, ...args: A]>;
		readonly OnClientEvent: Signal<A>;
		Fire(...args: A): void;
		FireClient(player: Player, ...args: A): void;
		FireClients(players: ReadonlyArray<Player>, ...args: A): void;
		FireExcept(player: Player, ...args: A): void;
		Response<R extends unknown[]>(...types: R): Request<A, R>;
		Unreliable(): Event<A>;
		RateLimit(count: number, interval: number): Event<A>;
		Validate(validator: (player: Player, ...args: A) => boolean): Event<A>;
		Serialize(...args: A): LuaTuple<[buffer, Array<Instance> | undefined]>;
		Deserialize(data: buffer, instances?: ReadonlyArray<Instance>): Results<A>;
	}

	interface Request<A extends unknown[], R extends unknown[]> {
		readonly Name: string;
		OnServerInvoke?: (player: Player, ...args: A) => Results<R>;
		OnClientInvoke?: (...args: A) => Results<R>;
		Fire(...args: A): Results<R>;
		FireClient(player: Player, ...args: A): Results<R>;
		SetServerInvoke(handler: (player: Player, ...args: A) => Results<R>): Request<A, R>;
		SetClientInvoke(handler: (...args: A) => Results<R>): Request<A, R>;
		Timeout(seconds: number, ...fallback: R): Request<A, R>;
		RateLimit(count: number, interval: number): Request<A, R>;
		Validate(validator: (player: Player, ...args: A) => boolean): Request<A, R>;
		Serialize(...args: A): LuaTuple<[buffer, Array<Instance> | undefined]>;
		Deserialize(data: buffer, instances?: ReadonlyArray<Instance>): Results<A>;
	}

	interface Library {
		<A extends unknown[]>(name: string, ...types: A): Event<A>;

		readonly Version: string;
		readonly Configure: (options: Options) => void;

		readonly Any: unknown;
		readonly Nil: undefined;
		readonly Boolean: boolean;

		readonly U8: number;
		readonly U16: number;
		readonly U24: number;
		readonly U32: number;
		readonly I8: number;
		readonly I16: number;
		readonly I24: number;
		readonly I32: number;
		readonly F16: number;
		readonly F24: number;
		readonly F32: number;
		readonly F64: number;

		readonly String: string;
		readonly Characters: string;
		readonly Buffer: buffer;
		readonly Instance: Instance | undefined;

		readonly Vector2: Vector2;
		readonly Vector2F16: Vector2;
		readonly Vector2I16: Vector2;
		readonly Vector3: Vector3;
		readonly Vector3F24: Vector3;
		readonly Vector3F16: Vector3;
		readonly Vector3I16: Vector3;
		readonly CFrame: CFrame;
		readonly CFrameF24: CFrame;

		readonly Color3: Color3;
		readonly BrickColor: BrickColor;
		readonly UDim: UDim;
		readonly UDim2: UDim2;
		readonly Rect: Rect;
		readonly NumberRange: NumberRange;
		readonly NumberSequence: NumberSequence;
		readonly ColorSequence: ColorSequence;
		readonly DateTime: DateTime;

		readonly Array: <T>(element: T, maximumLength?: number) => Array<T>;
		readonly Map: <K, V>(key: K, value: V, maximumCount?: number) => Map<K, V>;
		readonly Struct: <T extends object>(shape: T) => Flatten<Shape<T>>;
		readonly Optional: <T>(inner: T) => T | undefined;
		readonly Static: <const T>(values: ReadonlyArray<T>) => T;
		readonly Range: (inner: number, minimum: number, maximum: number) => number;
		readonly Flags: <const N extends string>(names: ReadonlyArray<N>) => Record<N, boolean>;
		readonly Charset: (characters: string) => string;
		readonly InstanceOf: <T extends keyof Instances>(className: T) => Instances[T] | undefined;
		readonly EnumItem: <T extends EnumItem>(enumType: { GetEnumItems(): Array<T> }) => T;
	}
}

declare const SwiftPacket: SwiftPacket.Library;

export = SwiftPacket;
