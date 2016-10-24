import Foundation

let tamVector   = 23
let posVector   = 9
let tamPeriodo  = 6
let nInsts      = 6
let largoLinea  = posVector + nInsts * tamVector * tamPeriodo + 1
let tamSalida   = posVector + 1 + tamVector * tamPeriodo + 1
let tamVecEntradaBytes = nInsts * tamVector * tamPeriodo
let tamVecSalidaBytes  = tamVector * tamPeriodo
let N : UInt8 = 78 // letra N
let S : UInt8 = 83 // letra S
let D : UInt8 = 68 // letra D
let NL : UInt8 = 10 // newline
let CERO : UInt8 = 48 // caracter '0'
let SPACE : UInt8 = 32

let ceroData = Data(repeating: CERO, count: tamPeriodo)

func ordenarVector(_ buf: Data) -> (tam:Int, data:Data) {
	var trabajo = Data(repeating: CERO, count: tamVecEntradaBytes)
	var p = 0
	var n = 0
	while p < tamVecEntradaBytes {
		let periodo = buf.subdata(in:p..<p+tamPeriodo)
		if periodo == ceroData {
			p += tamPeriodo
			continue
		}
		var i = 0
		var q = 0
		while i < n && periodo.lexicographicallyPrecedes(trabajo.subdata(in:q..<q+tamPeriodo)) {
			i += 1
			q += tamPeriodo
		}

		if i < n && periodo == trabajo.subdata(in:q..<q+tamPeriodo) {
			p += tamPeriodo
			continue
		}

		if i == n {
			q = n * tamPeriodo
			trabajo.replaceSubrange(q..<q+tamPeriodo, with: periodo)
		} else {
			var j = tamVector-1
			while j > i {
				q = j * tamPeriodo
				trabajo.replaceSubrange(q..<q+tamPeriodo, with: trabajo.subdata(in:q-tamPeriodo..<q))
				j -= 1
			}
			q = i * tamPeriodo
			trabajo.replaceSubrange(q..<q+tamPeriodo, with: periodo)
		}
		n += 1
		p += tamPeriodo
	}
	return (n, trabajo.subdata(in:0..<tamVecSalidaBytes))
}

func procesarLinea(_ buf: Data, _ nl: Int) -> Data {
	if buf.count != largoLinea {
		print("!!! Largo incorrecto en linea \(nl) \(largoLinea) != \(buf.count)")
		return buf
	} else {
		var result = Data(repeating: SPACE, count: tamSalida+1)
		let res = ordenarVector(buf.subdata(in:posVector..<buf.count))
		result.replaceSubrange(0..<posVector, with: buf.subdata(in:0..<posVector))
		if res.tam == 0 {
			result[posVector] = N
		} else if res.tam > tamVector {
			result[posVector] = S
		} else {
			result[posVector] = D
			result.replaceSubrange(posVector+1..<res.tam*tamPeriodo, with: res.data.subdata(in:0..<res.tam*tamPeriodo))
		}
		result[tamSalida-1] = NL
		result[tamSalida] = 0
		return result
	}
}


let args = ProcessInfo.processInfo.arguments
let argc = ProcessInfo.processInfo.arguments.count

if argc != 3 {
	print("Uso: ordenar_vector archivo_entrada archivo_salida")
	exit(-1)
} else {
	let start = Date()
	let entrada = args[1]
	let salida  = args[2]
	let fentrada = fopen(entrada, "rt")
	if fentrada == nil {
		print("no pudo abrir archivo entrada: \(entrada)")
		exit(-1)
	}
	let fsalida = fopen(salida, "wt")
	if fsalida == nil {
		print("no pudo abrir archivo salida: \(salida)")
		exit(-1)
	}

	let BUFFER_SIZE : Int32 = 4096
	var buf = [Int8](repeating: 0, count: Int(BUFFER_SIZE))
	var n = 0
	while (fgets(&buf, BUFFER_SIZE, fentrada) != nil) {
		let dataIn = Data(bytes: &buf, count: Int(strlen(buf)))
		let dataOut = procesarLinea(dataIn, n)
		let bufOut = dataOut.withUnsafeBytes {
    		[Int8](UnsafeBufferPointer(start: $0, count: tamSalida+1))
		}
		fputs(bufOut, fsalida)
		n += 1
	}
	fclose(fentrada)
	fclose(fsalida)
	
	let end = Date()
	let timeInterval = end.timeIntervalSince(start)
	let secs = timeInterval.truncatingRemainder(dividingBy:3600.0)
	print(String(format:"tiempo ocupado: %05.2f",  secs))
}
