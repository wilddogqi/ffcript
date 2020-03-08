(function(exports) {
	var invalidParamStr = 'Invalid parameter';
	var missingParamStr = 'Missing parameter';

	// app id
	FFAppId = [NSBundle mainBundle].bundleIdentifier;

	// mainBundlePath
	FFAppPath = [NSBundle mainBundle].bundlePath;

	// document path
	FFDocPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];

	// caches path
	FFCachesPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0]; 

	// 加载系统动态库
	FFLoadFramework = function(name) {
		var head = "/System/Library/";
		var foot = "Frameworks/" + name + ".framework";
		var bundle = [NSBundle bundleWithPath:head + foot] || [NSBundle bundleWithPath:head + "Private" + foot];
  		[bundle load];
  		return bundle;
	};

	// keyWindow
	FFKeyWin = function() {
		return UIApp.keyWindow;
	};

	// 根控制器
	FFRootVc =  function() {
		return UIApp.keyWindow.rootViewController;
	};

	// 找到显示在最前面的控制器
	var _FFFrontVc = function(vc) {
		if (vc.presentedViewController) {
        	return _FFFrontVc(vc.presentedViewController);
	    }else if ([vc isKindOfClass:[UITabBarController class]]) {
	        return _FFFrontVc(vc.selectedViewController);
	    } else if ([vc isKindOfClass:[UINavigationController class]]) {
	        return _FFFrontVc(vc.visibleViewController);
	    } else {
	    	var count = vc.childViewControllers.count;
    		for (var i = count - 1; i >= 0; i--) {
    			var childVc = vc.childViewControllers[i];
    			if (childVc && childVc.view.window) {
    				vc = _FFFrontVc(childVc);
    				break;
    			}
    		}
	        return vc;
    	}
	};

	FFFrontVc = function() {
		return _FFFrontVc(UIApp.keyWindow.rootViewController);
	};

	// 递归打印UIViewController view的层级结构
	FFVcSubviews = function(vc) { 
		if (![vc isKindOfClass:[UIViewController class]]) throw new Error(invalidParamStr);
		return vc.view.recursiveDescription().toString(); 
	};

	// 递归打印最上层UIViewController view的层级结构
	FFFrontVcSubViews = function() {
		return FFVcSubviews(_FFFrontVc(UIApp.keyWindow.rootViewController));
	};

	// 获取按钮绑定的所有TouchUpInside事件的方法名
	FFBtnTouchUpEvent = function(btn) { 
		var events = [];
		var allTargets = btn.allTargets().allObjects()
		var count = allTargets.count;
    	for (var i = count - 1; i >= 0; i--) { 
    		if (btn != allTargets[i]) {
    			var e = [btn actionsForTarget:allTargets[i] forControlEvent:UIControlEventTouchUpInside];
    			events.push(e);
    		}
    	}
	   return events;
	};

	// CG函数
	FFPointMake = function(x, y) { 
		return {0 : x, 1 : y}; 
	};

	FFSizeMake = function(w, h) { 
		return {0 : w, 1 : h}; 
	};

	FFRectMake = function(x, y, w, h) { 
		return {0 : FFPointMake(x, y), 1 : FFSizeMake(w, h)}; 
	};

	// 递归打印controller的层级结构
	FFChildVcs = function(vc) {
		if (![vc isKindOfClass:[UIViewController class]]) throw new Error(invalidParamStr);
		return [vc _printHierarchy].toString();
	};

	


	// 递归打印view的层级结构
	FFSubviews = function(view) { 
		if (![view isKindOfClass:[UIView class]]) throw new Error(invalidParamStr);
		return view.recursiveDescription().toString(); 
	};

	// 判断是否为字符串 "str" @"str"
	FFIsString = function(str) {
		return typeof str == 'string' || str instanceof String;
	};

	// 判断是否为数组 []、@[]
	FFIsArray = function(arr) {
		return arr instanceof Array;
	};

	// 判断是否为数字 666 @666
	FFIsNumber = function(num) {
		return typeof num == 'number' || num instanceof Number;
	};

	var _FFClass = function(className) {
		if (!className) throw new Error(missingParamStr);
		if (FFIsString(className)) {
			return NSClassFromString(className);
		} 
		if (!className) throw new Error(invalidParamStr);
		// 对象或者类
		return className.class();
	};

	// 打印所有的子类
	FFSubclasses = function(className, reg) {
		className = _FFClass(className);

		return [c for each (c in ObjectiveC.classes) 
		if (c != className 
			&& class_getSuperclass(c) 
			&& [c isSubclassOfClass:className] 
			&& (!reg || reg.test(c)))
			];
	};

	// 打印所有的方法
	var _FFGetMethods = function(className, reg, clazz) {
		className = _FFClass(className);

		var count = new new Type('I');
		var classObj = clazz ? className.constructor : className;
		var methodList = class_copyMethodList(classObj, count);
		var methodsArray = [];
		var methodNamesArray = [];
		for(var i = 0; i < *count; i++) {
			var method = methodList[i];
			var selector = method_getName(method);
			var name = sel_getName(selector);
			if (reg && !reg.test(name)) continue;
			methodsArray.push({
				selector : selector, 
				type : method_getTypeEncoding(method)
			});
			methodNamesArray.push(name);
		}
		free(methodList);
		return [methodsArray, methodNamesArray];
	};

	var _FFMethods = function(className, reg, clazz) {
		return _FFGetMethods(className, reg, clazz)[0];
	};

	// 打印所有的方法名字
	var _FFMethodNames = function(className, reg, clazz) {
		return _FFGetMethods(className, reg, clazz)[1];
	};

	// 打印所有的对象方法
	FFInstanceMethods = function(className, reg) {
		return _FFMethods(className, reg);
	};

	// 打印所有的对象方法名字
	FFInstanceMethodNames = function(className, reg) {
		return _FFMethodNames(className, reg);
	};

	// 打印所有的类方法
	FFClassMethods = function(className, reg) {
		return _FFMethods(className, reg, true);
	};

	// 打印所有的类方法名字
	FFClassMethodNames = function(className, reg) {
		return _FFMethodNames(className, reg, true);
	};

	// 打印所有的成员变量
	FFIvars = function(obj, reg){ 
		if (!obj) throw new Error(missingParamStr);
		var x = {}; 
		for(var i in *obj) { 
			try { 
				var value = (*obj)[i];
				if (reg && !reg.test(i) && !reg.test(value)) continue;
				x[i] = value; 
			} catch(e){} 
		} 
		return x; 
	};

	// 打印所有的成员变量名字
	FFIvarNames = function(obj, reg) {
		if (!obj) throw new Error(missingParamStr);
		var array = [];
		for(var name in *obj) { 
			if (reg && !reg.test(name)) continue;
			array.push(name);
		}
		return array;
	};
})(exports);