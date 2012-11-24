/*--------------------------------------------------------------------------
 *
 *	Key Oriented JSON Application Cache (KOJAC)
 *	(c) 2011-12 Buzzware Solutions
 *  https://github.com/buzzware/KOJAC
 *
 *	KOJAC is freely distributable under the terms of an MIT-style license.
 *
 *--------------------------------------------------------------------------*/
/*
 Handler Stack

 The call back handlers are in a stack. This means :
 * whether writing application code or the Kojac framework, you can push a handler before calling a method with the KojacRequest,
 and when the framework action is complete, it will aRequest.callNextHandler().
 * Each handler themselves finish with aRequest.callNextHandler().
 * It is good practice to end a handler with aRequest.callNextHandler() even when you don't think there are further handlers to call,
 as the method will simply return without error
 * a handler's signature is function (aRequest: KojacRequest): void
 * handlers should check the error property and act appropriately
 * if an exception is left uncaught, the error property will be set with it unless it is already set. callNext() will then be called,
 * so you don't have to ensure that callNext() is called in the case of exceptions. If this is not desired, do not let exceptions leak out
 *
 * Support :
 * - sequence via add(aHandler)
 * - call() for calling the first time
 * - repeat() which calls the last popped handler again
 * -
 *
 */
package au.com.buzzware.kojac {
import au.com.buzzware.actiontools4.code.EventUtils;
import au.com.buzzware.actiontools4.code.StringUtils;

import flash.events.ErrorEvent;
import flash.utils.getQualifiedClassName;

public class HandlerStack {
	public var command: Object;
	protected var _handlers: Array = [];
	protected var _parameters: Array = [];
	public var waitForCallNext: Boolean;
	public var parameter: *;
	public var errorHandler: Function;

	function HandlerStack() {
		errorHandler = defaultErrorHandler
	}

	public function handleError(aError: *): void {
		if (errorHandler != null) {
			try {
				errorHandler(this, aError);
			} catch (e: Error) {
				trace('!!! Error in error handler !!!')
				throw e
			}
		}
	}

	protected function defaultErrorHandler(aHandlerStack: HandlerStack, aError: *): void {
		try {
			command.error = aError
		} catch (e: Error) {
		}
		var e: Error = aError as Error
		var ee: ErrorEvent = aError as ErrorEvent
		if (e) {
			// allow flexunit exceptions
			var errorClass: String = getQualifiedClassName(e)
			if (StringUtils.beginsWith(errorClass, 'org.flexunit.') || StringUtils.beginsWith(errorClass, 'org.hamcrest.') || StringUtils.beginsWith(errorClass, 'flexunit.framework.'))
				throw e;
			trace('There was an error in a handler:' + e.message);
			trace(e.getStackTrace() || '');
		} else if (ee) {
			trace('There was an error in a handler:' + ee.text);
		} else {
			trace('There was an error in a handler');
		}
	}

	public function push(aFunction: Function, aData: * = null): void {
		_handlers.unshift(aFunction)
		_parameters.unshift(aData)
	}

	public function add(f: Function, aData: * = null): void {
		_handlers.push(f)
		_parameters.push(aData)
	}

	// call the next handler
	//!!! maybe this needs a callback to enable action after the next handler
	public function callNext(): void {
		if (!_handlers.length)
			return;
		var fn: Function = _handlers.shift()
		var d: * = _parameters.shift()
		EventUtils.callLater(0, function (aSomething: *): void {
			executeHandler(fn, d);
		})
	}

	protected function executeHandler(fn: Function, d: *): void {
		waitForCallNext = false
		try {
			parameter = d
			fn(command)
		} catch (e: Error) {
			handleError(e)
		}
		if (!waitForCallNext)
			callNext();
	}

	// call this to execute the stack of handlers
	public function call(aCommand: Object): void {
		command = aCommand
		callNext()
	}

	// convenience function that causes another waiting stack to continue when the given handler is executed in this stack eg. for nested stacks
	public function pushCallNextFor(anotherHandlerStack: HandlerStack): void {
		push(function (aCommand: Object): void {
			anotherHandlerStack.callNext()
		})
	}

	public function pushTimes(aTimes: int, aHandler: Function, aData: * = null): void {
		for (var i: int = 0; i < aTimes; i++) {
			push(aHandler, aData)
		}
	}

}
}
