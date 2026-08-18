// cropperjs@1.6.2 downloaded from https://ga.jspm.io/npm:cropperjs@1.6.2/dist/cropper.js

var t=typeof globalThis!=="undefined"?globalThis:typeof self!=="undefined"?self:global;var e={};(function(t,i){e=i()})(0,(function(){function ownKeys(t,e){var i=Object.keys(t);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(t);e&&(a=a.filter((function(e){return Object.getOwnPropertyDescriptor(t,e).enumerable}))),i.push.apply(i,a)}return i}function _objectSpread2(t){for(var e=1;e<arguments.length;e++){var i=null!=arguments[e]?arguments[e]:{};e%2?ownKeys(Object(i),!0).forEach((function(e){_defineProperty(t,e,i[e])})):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(i)):ownKeys(Object(i)).forEach((function(e){Object.defineProperty(t,e,Object.getOwnPropertyDescriptor(i,e))}))}return t}function _toPrimitive(t,e){if("object"!=typeof t||!t)return t;var i=t[Symbol.toPrimitive];if(void 0!==i){var a=i.call(t,e||"default");if("object"!=typeof a)return a;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===e?String:Number)(t)}function _toPropertyKey(t){var e=_toPrimitive(t,"string");return"symbol"==typeof e?e:e+""}function _typeof(t){return _typeof="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(t){return typeof t}:function(t){return t&&"function"==typeof Symbol&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},_typeof(t)}function _classCallCheck(t,e){if(!(t instanceof e))throw new TypeError("Cannot call a class as a function")}function _defineProperties(t,e){for(var i=0;i<e.length;i++){var a=e[i];a.enumerable=a.enumerable||false;a.configurable=true;"value"in a&&(a.writable=true);Object.defineProperty(t,_toPropertyKey(a.key),a)}}function _createClass(t,e,i){e&&_defineProperties(t.prototype,e);i&&_defineProperties(t,i);Object.defineProperty(t,"prototype",{writable:false});return t}function _defineProperty(t,e,i){e=_toPropertyKey(e);e in t?Object.defineProperty(t,e,{value:i,enumerable:true,configurable:true,writable:true}):t[e]=i;return t}function _toConsumableArray(t){return _arrayWithoutHoles(t)||_iterableToArray(t)||_unsupportedIterableToArray(t)||_nonIterableSpread()}function _arrayWithoutHoles(t){if(Array.isArray(t))return _arrayLikeToArray(t)}function _iterableToArray(t){if(typeof Symbol!=="undefined"&&t[Symbol.iterator]!=null||t["@@iterator"]!=null)return Array.from(t)}function _unsupportedIterableToArray(t,e){if(t){if(typeof t==="string")return _arrayLikeToArray(t,e);var i=Object.prototype.toString.call(t).slice(8,-1);i==="Object"&&t.constructor&&(i=t.constructor.name);return i==="Map"||i==="Set"?Array.from(t):i==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(i)?_arrayLikeToArray(t,e):void 0}}function _arrayLikeToArray(t,e){(e==null||e>t.length)&&(e=t.length);for(var i=0,a=new Array(e);i<e;i++)a[i]=t[i];return a}function _nonIterableSpread(){throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}var e=typeof window!=="undefined"&&typeof window.document!=="undefined";var i=e?window:{};var a=!(!e||!i.document.documentElement)&&"ontouchstart"in i.document.documentElement;var r=!!e&&"PointerEvent"in i;var n="cropper";var o="all";var s="crop";var h="move";var c="zoom";var l="e";var d="w";var p="s";var u="n";var f="ne";var v="nw";var m="se";var g="sw";var b="".concat(n,"-crop");var w="".concat(n,"-disabled");var y="".concat(n,"-hidden");var x="".concat(n,"-hide");var C="".concat(n,"-invisible");var D="".concat(n,"-modal");var M="".concat(n,"-move");var N="".concat(n,"Action");var O="".concat(n,"Preview");var E="crop";var T="move";var L="none";var B="crop";var k="cropend";var S="cropmove";var z="cropstart";var A="dblclick";var j=a?"touchstart":"mousedown";var W=a?"touchmove":"mousemove";var P=a?"touchend touchcancel":"mouseup";var H=r?"pointerdown":j;var R=r?"pointermove":W;var Y=r?"pointerup pointercancel":P;var X="ready";var I="resize";var _="wheel";var U="zoom";var F="image/jpeg";var q=/^e|w|s|n|se|sw|ne|nw|all|crop|move|zoom$/;var K=/^data:/;var $=/^data:image\/jpeg;base64,/;var Z=/^img|canvas$/i;var Q=200;var G=100;var V={viewMode:0,dragMode:E,initialAspectRatio:NaN,aspectRatio:NaN,data:null,preview:"",responsive:true,restore:true,checkCrossOrigin:true,checkOrientation:true,modal:true,guides:true,center:true,highlight:true,background:true,autoCrop:true,autoCropArea:.8,movable:true,rotatable:true,scalable:true,zoomable:true,zoomOnTouch:true,zoomOnWheel:true,wheelZoomRatio:.1,cropBoxMovable:true,cropBoxResizable:true,toggleDragModeOnDblclick:true,minCanvasWidth:0,minCanvasHeight:0,minCropBoxWidth:0,minCropBoxHeight:0,minContainerWidth:Q,minContainerHeight:G,ready:null,cropstart:null,cropmove:null,cropend:null,crop:null,zoom:null};var J='<div class="cropper-container" touch-action="none"><div class="cropper-wrap-box"><div class="cropper-canvas"></div></div><div class="cropper-drag-box"></div><div class="cropper-crop-box"><span class="cropper-view-box"></span><span class="cropper-dashed dashed-h"></span><span class="cropper-dashed dashed-v"></span><span class="cropper-center"></span><span class="cropper-face"></span><span class="cropper-line line-e" data-cropper-action="e"></span><span class="cropper-line line-n" data-cropper-action="n"></span><span class="cropper-line line-w" data-cropper-action="w"></span><span class="cropper-line line-s" data-cropper-action="s"></span><span class="cropper-point point-e" data-cropper-action="e"></span><span class="cropper-point point-n" data-cropper-action="n"></span><span class="cropper-point point-w" data-cropper-action="w"></span><span class="cropper-point point-s" data-cropper-action="s"></span><span class="cropper-point point-ne" data-cropper-action="ne"></span><span class="cropper-point point-nw" data-cropper-action="nw"></span><span class="cropper-point point-sw" data-cropper-action="sw"></span><span class="cropper-point point-se" data-cropper-action="se"></span></div></div>';var tt=Number.isNaN||i.isNaN;
/**
   * Check if the given value is a number.
   * @param {*} value - The value to check.
   * @returns {boolean} Returns `true` if the given value is a number, else `false`.
   */function isNumber(t){return typeof t==="number"&&!tt(t)}
/**
   * Check if the given value is a positive number.
   * @param {*} value - The value to check.
   * @returns {boolean} Returns `true` if the given value is a positive number, else `false`.
   */var et=function isPositiveNumber(t){return t>0&&t<Infinity};
/**
   * Check if the given value is undefined.
   * @param {*} value - The value to check.
   * @returns {boolean} Returns `true` if the given value is undefined, else `false`.
   */function isUndefined(t){return typeof t==="undefined"}
/**
   * Check if the given value is an object.
   * @param {*} value - The value to check.
   * @returns {boolean} Returns `true` if the given value is an object, else `false`.
   */function isObject(t){return _typeof(t)==="object"&&t!==null}var it=Object.prototype.hasOwnProperty;
/**
   * Check if the given value is a plain object.
   * @param {*} value - The value to check.
   * @returns {boolean} Returns `true` if the given value is a plain object, else `false`.
   */function isPlainObject(t){if(!isObject(t))return false;try{var e=t.constructor;var i=e.prototype;return e&&i&&it.call(i,"isPrototypeOf")}catch(t){return false}}
/**
   * Check if the given value is a function.
   * @param {*} value - The value to check.
   * @returns {boolean} Returns `true` if the given value is a function, else `false`.
   */function isFunction(t){return typeof t==="function"}var at=Array.prototype.slice;
/**
   * Convert array-like or iterable object to an array.
   * @param {*} value - The value to convert.
   * @returns {Array} Returns a new array.
   */function toArray(t){return Array.from?Array.from(t):at.call(t)}
/**
   * Iterate the given data.
   * @param {*} data - The data to iterate.
   * @param {Function} callback - The process function for each element.
   * @returns {*} The original data.
   */function forEach(t,e){t&&isFunction(e)&&(Array.isArray(t)||isNumber(t.length)?toArray(t).forEach((function(i,a){e.call(t,i,a,t)})):isObject(t)&&Object.keys(t).forEach((function(i){e.call(t,t[i],i,t)})));return t}
/**
   * Extend the given object.
   * @param {*} target - The target object to extend.
   * @param {*} args - The rest objects for merging to the target object.
   * @returns {Object} The extended object.
   */var rt=Object.assign||function assign(t){for(var e=arguments.length,i=new Array(e>1?e-1:0),a=1;a<e;a++)i[a-1]=arguments[a];isObject(t)&&i.length>0&&i.forEach((function(e){isObject(e)&&Object.keys(e).forEach((function(i){t[i]=e[i]}))}));return t};var nt=/\.\d*(?:0|9){12}\d*$/;
/**
   * Normalize decimal number.
   * Check out {@link https://0.30000000000000004.com/}
   * @param {number} value - The value to normalize.
   * @param {number} [times=100000000000] - The times for normalizing.
   * @returns {number} Returns the normalized number.
   */function normalizeDecimalNumber(t){var e=arguments.length>1&&arguments[1]!==void 0?arguments[1]:1e11;return nt.test(t)?Math.round(t*e)/e:t}var ot=/^width|height|left|top|marginLeft|marginTop$/;
/**
   * Apply styles to the given element.
   * @param {Element} element - The target element.
   * @param {Object} styles - The styles for applying.
   */function setStyle(t,e){var i=t.style;forEach(e,(function(t,e){ot.test(e)&&isNumber(t)&&(t="".concat(t,"px"));i[e]=t}))}
/**
   * Check if the given element has a special class.
   * @param {Element} element - The element to check.
   * @param {string} value - The class to search.
   * @returns {boolean} Returns `true` if the special class was found.
   */function hasClass(t,e){return t.classList?t.classList.contains(e):t.className.indexOf(e)>-1}
/**
   * Add classes to the given element.
   * @param {Element} element - The target element.
   * @param {string} value - The classes to be added.
   */function addClass(t,e){if(e)if(isNumber(t.length))forEach(t,(function(t){addClass(t,e)}));else if(t.classList)t.classList.add(e);else{var i=t.className.trim();i?i.indexOf(e)<0&&(t.className="".concat(i," ").concat(e)):t.className=e}}
/**
   * Remove classes from the given element.
   * @param {Element} element - The target element.
   * @param {string} value - The classes to be removed.
   */function removeClass(t,e){e&&(isNumber(t.length)?forEach(t,(function(t){removeClass(t,e)})):t.classList?t.classList.remove(e):t.className.indexOf(e)>=0&&(t.className=t.className.replace(e,"")))}
/**
   * Add or remove classes from the given element.
   * @param {Element} element - The target element.
   * @param {string} value - The classes to be toggled.
   * @param {boolean} added - Add only.
   */function toggleClass(t,e,i){e&&(isNumber(t.length)?forEach(t,(function(t){toggleClass(t,e,i)})):i?addClass(t,e):removeClass(t,e))}var st=/([a-z\d])([A-Z])/g;
/**
   * Transform the given string from camelCase to kebab-case
   * @param {string} value - The value to transform.
   * @returns {string} The transformed value.
   */function toParamCase(t){return t.replace(st,"$1-$2").toLowerCase()}
/**
   * Get data from the given element.
   * @param {Element} element - The target element.
   * @param {string} name - The data key to get.
   * @returns {string} The data value.
   */function getData(t,e){return isObject(t[e])?t[e]:t.dataset?t.dataset[e]:t.getAttribute("data-".concat(toParamCase(e)))}
/**
   * Set data to the given element.
   * @param {Element} element - The target element.
   * @param {string} name - The data key to set.
   * @param {string} data - The data value.
   */function setData(t,e,i){isObject(i)?t[e]=i:t.dataset?t.dataset[e]=i:t.setAttribute("data-".concat(toParamCase(e)),i)}
/**
   * Remove data from the given element.
   * @param {Element} element - The target element.
   * @param {string} name - The data key to remove.
   */function removeData(t,e){if(isObject(t[e]))try{delete t[e]}catch(i){t[e]=void 0}else if(t.dataset)try{delete t.dataset[e]}catch(i){t.dataset[e]=void 0}else t.removeAttribute("data-".concat(toParamCase(e)))}var ht=/\s\s*/;var ct=function(){var t=false;if(e){var a=false;var r=function listener(){};var n=Object.defineProperty({},"once",{get:function get(){t=true;return a},
/**
         * This setter can fix a `TypeError` in strict mode
         * {@link https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Errors/Getter_only}
         * @param {boolean} value - The value to set
         */
set:function set(t){a=t}});i.addEventListener("test",r,n);i.removeEventListener("test",r,n)}return t}();
/**
   * Remove event listener from the target element.
   * @param {Element} element - The event target.
   * @param {string} type - The event type(s).
   * @param {Function} listener - The event listener.
   * @param {Object} options - The event options.
   */function removeListener(t,e,i){var a=arguments.length>3&&arguments[3]!==void 0?arguments[3]:{};var r=i;e.trim().split(ht).forEach((function(e){if(!ct){var n=t.listeners;if(n&&n[e]&&n[e][i]){r=n[e][i];delete n[e][i];Object.keys(n[e]).length===0&&delete n[e];Object.keys(n).length===0&&delete t.listeners}}t.removeEventListener(e,r,a)}))}
/**
   * Add event listener to the target element.
   * @param {Element} element - The event target.
   * @param {string} type - The event type(s).
   * @param {Function} listener - The event listener.
   * @param {Object} options - The event options.
   */function addListener(t,e,i){var a=arguments.length>3&&arguments[3]!==void 0?arguments[3]:{};var r=i;e.trim().split(ht).forEach((function(e){if(a.once&&!ct){var n=t.listeners,o=n===void 0?{}:n;r=function handler(){delete o[e][i];t.removeEventListener(e,r,a);for(var n=arguments.length,s=new Array(n),h=0;h<n;h++)s[h]=arguments[h];i.apply(t,s)};o[e]||(o[e]={});o[e][i]&&t.removeEventListener(e,o[e][i],a);o[e][i]=r;t.listeners=o}t.addEventListener(e,r,a)}))}
/**
   * Dispatch event on the target element.
   * @param {Element} element - The event target.
   * @param {string} type - The event type(s).
   * @param {Object} data - The additional event data.
   * @returns {boolean} Indicate if the event is default prevented or not.
   */function dispatchEvent(t,e,i){var a;if(isFunction(Event)&&isFunction(CustomEvent))a=new CustomEvent(e,{detail:i,bubbles:true,cancelable:true});else{a=document.createEvent("CustomEvent");a.initCustomEvent(e,true,true,i)}return t.dispatchEvent(a)}
/**
   * Get the offset base on the document.
   * @param {Element} element - The target element.
   * @returns {Object} The offset data.
   */function getOffset(t){var e=t.getBoundingClientRect();return{left:e.left+(window.pageXOffset-document.documentElement.clientLeft),top:e.top+(window.pageYOffset-document.documentElement.clientTop)}}var lt=i.location;var dt=/^(\w+:)\/\/([^:/?#]*):?(\d*)/i;
/**
   * Check if the given URL is a cross origin URL.
   * @param {string} url - The target URL.
   * @returns {boolean} Returns `true` if the given URL is a cross origin URL, else `false`.
   */function isCrossOriginURL(t){var e=t.match(dt);return e!==null&&(e[1]!==lt.protocol||e[2]!==lt.hostname||e[3]!==lt.port)}
/**
   * Add timestamp to the given URL.
   * @param {string} url - The target URL.
   * @returns {string} The result URL.
   */function addTimestamp(t){var e="timestamp=".concat((new Date).getTime());return t+(t.indexOf("?")===-1?"?":"&")+e}
/**
   * Get transforms base on the given object.
   * @param {Object} obj - The target object.
   * @returns {string} A string contains transform values.
   */function getTransforms(t){var e=t.rotate,i=t.scaleX,a=t.scaleY,r=t.translateX,n=t.translateY;var o=[];isNumber(r)&&r!==0&&o.push("translateX(".concat(r,"px)"));isNumber(n)&&n!==0&&o.push("translateY(".concat(n,"px)"));isNumber(e)&&e!==0&&o.push("rotate(".concat(e,"deg)"));isNumber(i)&&i!==1&&o.push("scaleX(".concat(i,")"));isNumber(a)&&a!==1&&o.push("scaleY(".concat(a,")"));var s=o.length?o.join(" "):"none";return{WebkitTransform:s,msTransform:s,transform:s}}
/**
   * Get the max ratio of a group of pointers.
   * @param {string} pointers - The target pointers.
   * @returns {number} The result ratio.
   */function getMaxZoomRatio(t){var e=_objectSpread2({},t);var i=0;forEach(t,(function(t,a){delete e[a];forEach(e,(function(e){var a=Math.abs(t.startX-e.startX);var r=Math.abs(t.startY-e.startY);var n=Math.abs(t.endX-e.endX);var o=Math.abs(t.endY-e.endY);var s=Math.sqrt(a*a+r*r);var h=Math.sqrt(n*n+o*o);var c=(h-s)/s;Math.abs(c)>Math.abs(i)&&(i=c)}))}));return i}
/**
   * Get a pointer from an event object.
   * @param {Object} event - The target event object.
   * @param {boolean} endOnly - Indicates if only returns the end point coordinate or not.
   * @returns {Object} The result pointer contains start and/or end point coordinates.
   */function getPointer(t,e){var i=t.pageX,a=t.pageY;var r={endX:i,endY:a};return e?r:_objectSpread2({startX:i,startY:a},r)}
/**
   * Get the center point coordinate of a group of pointers.
   * @param {Object} pointers - The target pointers.
   * @returns {Object} The center point coordinate.
   */function getPointersCenter(t){var e=0;var i=0;var a=0;forEach(t,(function(t){var r=t.startX,n=t.startY;e+=r;i+=n;a+=1}));e/=a;i/=a;return{pageX:e,pageY:i}}
/**
   * Get the max sizes in a rectangle under the given aspect ratio.
   * @param {Object} data - The original sizes.
   * @param {string} [type='contain'] - The adjust type.
   * @returns {Object} The result sizes.
   */function getAdjustedSizes(t){var e=t.aspectRatio,i=t.height,a=t.width;var r=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"contain";var n=et(a);var o=et(i);if(n&&o){var s=i*e;r==="contain"&&s>a||r==="cover"&&s<a?i=a/e:a=i*e}else n?i=a/e:o&&(a=i*e);return{width:a,height:i}}
/**
   * Get the new sizes of a rectangle after rotated.
   * @param {Object} data - The original sizes.
   * @returns {Object} The result sizes.
   */function getRotatedSizes(t){var e=t.width,i=t.height,a=t.degree;a=Math.abs(a)%180;if(a===90)return{width:i,height:e};var r=a%90*Math.PI/180;var n=Math.sin(r);var o=Math.cos(r);var s=e*o+i*n;var h=e*n+i*o;return a>90?{width:h,height:s}:{width:s,height:h}}
/**
   * Get a canvas which drew the given image.
   * @param {HTMLImageElement} image - The image for drawing.
   * @param {Object} imageData - The image data.
   * @param {Object} canvasData - The canvas data.
   * @param {Object} options - The options.
   * @returns {HTMLCanvasElement} The result canvas.
   */function getSourceCanvas(t,e,i,a){var r=e.aspectRatio,n=e.naturalWidth,o=e.naturalHeight,s=e.rotate,h=s===void 0?0:s,c=e.scaleX,l=c===void 0?1:c,d=e.scaleY,p=d===void 0?1:d;var u=i.aspectRatio,f=i.naturalWidth,v=i.naturalHeight;var m=a.fillColor,g=m===void 0?"transparent":m,b=a.imageSmoothingEnabled,w=b===void 0||b,y=a.imageSmoothingQuality,x=y===void 0?"low":y,C=a.maxWidth,D=C===void 0?Infinity:C,M=a.maxHeight,N=M===void 0?Infinity:M,O=a.minWidth,E=O===void 0?0:O,T=a.minHeight,L=T===void 0?0:T;var B=document.createElement("canvas");var k=B.getContext("2d");var S=getAdjustedSizes({aspectRatio:u,width:D,height:N});var z=getAdjustedSizes({aspectRatio:u,width:E,height:L},"cover");var A=Math.min(S.width,Math.max(z.width,f));var j=Math.min(S.height,Math.max(z.height,v));var W=getAdjustedSizes({aspectRatio:r,width:D,height:N});var P=getAdjustedSizes({aspectRatio:r,width:E,height:L},"cover");var H=Math.min(W.width,Math.max(P.width,n));var R=Math.min(W.height,Math.max(P.height,o));var Y=[-H/2,-R/2,H,R];B.width=normalizeDecimalNumber(A);B.height=normalizeDecimalNumber(j);k.fillStyle=g;k.fillRect(0,0,A,j);k.save();k.translate(A/2,j/2);k.rotate(h*Math.PI/180);k.scale(l,p);k.imageSmoothingEnabled=w;k.imageSmoothingQuality=x;k.drawImage.apply(k,[t].concat(_toConsumableArray(Y.map((function(t){return Math.floor(normalizeDecimalNumber(t))})))));k.restore();return B}var pt=String.fromCharCode;
/**
   * Get string from char code in data view.
   * @param {DataView} dataView - The data view for read.
   * @param {number} start - The start index.
   * @param {number} length - The read length.
   * @returns {string} The read result.
   */function getStringFromCharCode(t,e,i){var a="";i+=e;for(var r=e;r<i;r+=1)a+=pt(t.getUint8(r));return a}var ut=/^data:.*,/;
/**
   * Transform Data URL to array buffer.
   * @param {string} dataURL - The Data URL to transform.
   * @returns {ArrayBuffer} The result array buffer.
   */function dataURLToArrayBuffer(t){var e=t.replace(ut,"");var i=atob(e);var a=new ArrayBuffer(i.length);var r=new Uint8Array(a);forEach(r,(function(t,e){r[e]=i.charCodeAt(e)}));return a}
/**
   * Transform array buffer to Data URL.
   * @param {ArrayBuffer} arrayBuffer - The array buffer to transform.
   * @param {string} mimeType - The mime type of the Data URL.
   * @returns {string} The result Data URL.
   */function arrayBufferToDataURL(t,e){var i=[];var a=8192;var r=new Uint8Array(t);while(r.length>0){i.push(pt.apply(null,toArray(r.subarray(0,a))));r=r.subarray(a)}return"data:".concat(e,";base64,").concat(btoa(i.join("")))}
/**
   * Get orientation value from given array buffer.
   * @param {ArrayBuffer} arrayBuffer - The array buffer to read.
   * @returns {number} The read orientation value.
   */function resetAndGetOrientation(t){var e=new DataView(t);var i;try{var a;var r;var n;if(e.getUint8(0)===255&&e.getUint8(1)===216){var o=e.byteLength;var s=2;while(s+1<o){if(e.getUint8(s)===255&&e.getUint8(s+1)===225){r=s;break}s+=1}}if(r){var h=r+4;var c=r+10;if(getStringFromCharCode(e,h,4)==="Exif"){var l=e.getUint16(c);a=l===18761;if((a||l===19789)&&e.getUint16(c+2,a)===42){var d=e.getUint32(c+4,a);d>=8&&(n=c+d)}}}if(n){var p=e.getUint16(n,a);var u;var f;for(f=0;f<p;f+=1){u=n+f*12+2;if(e.getUint16(u,a)===274){u+=8;i=e.getUint16(u,a);e.setUint16(u,1,a);break}}}}catch(t){i=1}return i}
/**
   * Parse Exif Orientation value.
   * @param {number} orientation - The orientation to parse.
   * @returns {Object} The parsed result.
   */function parseOrientation(t){var e=0;var i=1;var a=1;switch(t){case 2:i=-1;break;case 3:e=-180;break;case 4:a=-1;break;case 5:e=90;a=-1;break;case 6:e=90;break;case 7:e=90;i=-1;break;case 8:e=-90;break}return{rotate:e,scaleX:i,scaleY:a}}var ft={render:function render(){this.initContainer();this.initCanvas();this.initCropBox();this.renderCanvas();(this||t).cropped&&this.renderCropBox()},initContainer:function initContainer(){var e=(this||t).element,i=(this||t).options,a=(this||t).container,r=(this||t).cropper;var n=Number(i.minContainerWidth);var o=Number(i.minContainerHeight);addClass(r,y);removeClass(e,y);var s={width:Math.max(a.offsetWidth,n>=0?n:Q),height:Math.max(a.offsetHeight,o>=0?o:G)};(this||t).containerData=s;setStyle(r,{width:s.width,height:s.height});addClass(e,y);removeClass(r,y)},initCanvas:function initCanvas(){var e=(this||t).containerData,i=(this||t).imageData;var a=(this||t).options.viewMode;var r=Math.abs(i.rotate)%180===90;var n=r?i.naturalHeight:i.naturalWidth;var o=r?i.naturalWidth:i.naturalHeight;var s=n/o;var h=e.width;var c=e.height;e.height*s>e.width?a===3?h=e.height*s:c=e.width/s:a===3?c=e.width/s:h=e.height*s;var l={aspectRatio:s,naturalWidth:n,naturalHeight:o,width:h,height:c};(this||t).canvasData=l;(this||t).limited=a===1||a===2;this.limitCanvas(true,true);l.width=Math.min(Math.max(l.width,l.minWidth),l.maxWidth);l.height=Math.min(Math.max(l.height,l.minHeight),l.maxHeight);l.left=(e.width-l.width)/2;l.top=(e.height-l.height)/2;l.oldLeft=l.left;l.oldTop=l.top;(this||t).initialCanvasData=rt({},l)},limitCanvas:function limitCanvas(e,i){var a=(this||t).options,r=(this||t).containerData,n=(this||t).canvasData,o=(this||t).cropBoxData;var s=a.viewMode;var h=n.aspectRatio;var c=(this||t).cropped&&o;if(e){var l=Number(a.minCanvasWidth)||0;var d=Number(a.minCanvasHeight)||0;if(s>1){l=Math.max(l,r.width);d=Math.max(d,r.height);s===3&&(d*h>l?l=d*h:d=l/h)}else if(s>0)if(l)l=Math.max(l,c?o.width:0);else if(d)d=Math.max(d,c?o.height:0);else if(c){l=o.width;d=o.height;d*h>l?l=d*h:d=l/h}var p=getAdjustedSizes({aspectRatio:h,width:l,height:d});l=p.width;d=p.height;n.minWidth=l;n.minHeight=d;n.maxWidth=Infinity;n.maxHeight=Infinity}if(i)if(s>(c?0:1)){var u=r.width-n.width;var f=r.height-n.height;n.minLeft=Math.min(0,u);n.minTop=Math.min(0,f);n.maxLeft=Math.max(0,u);n.maxTop=Math.max(0,f);if(c&&(this||t).limited){n.minLeft=Math.min(o.left,o.left+(o.width-n.width));n.minTop=Math.min(o.top,o.top+(o.height-n.height));n.maxLeft=o.left;n.maxTop=o.top;if(s===2){if(n.width>=r.width){n.minLeft=Math.min(0,u);n.maxLeft=Math.max(0,u)}if(n.height>=r.height){n.minTop=Math.min(0,f);n.maxTop=Math.max(0,f)}}}}else{n.minLeft=-n.width;n.minTop=-n.height;n.maxLeft=r.width;n.maxTop=r.height}},renderCanvas:function renderCanvas(e,i){var a=(this||t).canvasData,r=(this||t).imageData;if(i){var n=getRotatedSizes({width:r.naturalWidth*Math.abs(r.scaleX||1),height:r.naturalHeight*Math.abs(r.scaleY||1),degree:r.rotate||0}),o=n.width,s=n.height;var h=a.width*(o/a.naturalWidth);var c=a.height*(s/a.naturalHeight);a.left-=(h-a.width)/2;a.top-=(c-a.height)/2;a.width=h;a.height=c;a.aspectRatio=o/s;a.naturalWidth=o;a.naturalHeight=s;this.limitCanvas(true,false)}(a.width>a.maxWidth||a.width<a.minWidth)&&(a.left=a.oldLeft);(a.height>a.maxHeight||a.height<a.minHeight)&&(a.top=a.oldTop);a.width=Math.min(Math.max(a.width,a.minWidth),a.maxWidth);a.height=Math.min(Math.max(a.height,a.minHeight),a.maxHeight);this.limitCanvas(false,true);a.left=Math.min(Math.max(a.left,a.minLeft),a.maxLeft);a.top=Math.min(Math.max(a.top,a.minTop),a.maxTop);a.oldLeft=a.left;a.oldTop=a.top;setStyle((this||t).canvas,rt({width:a.width,height:a.height},getTransforms({translateX:a.left,translateY:a.top})));this.renderImage(e);(this||t).cropped&&(this||t).limited&&this.limitCropBox(true,true)},renderImage:function renderImage(e){var i=(this||t).canvasData,a=(this||t).imageData;var r=a.naturalWidth*(i.width/i.naturalWidth);var n=a.naturalHeight*(i.height/i.naturalHeight);rt(a,{width:r,height:n,left:(i.width-r)/2,top:(i.height-n)/2});setStyle((this||t).image,rt({width:a.width,height:a.height},getTransforms(rt({translateX:a.left,translateY:a.top},a))));e&&this.output()},initCropBox:function initCropBox(){var e=(this||t).options,i=(this||t).canvasData;var a=e.aspectRatio||e.initialAspectRatio;var r=Number(e.autoCropArea)||.8;var n={width:i.width,height:i.height};a&&(i.height*a>i.width?n.height=n.width/a:n.width=n.height*a);(this||t).cropBoxData=n;this.limitCropBox(true,true);n.width=Math.min(Math.max(n.width,n.minWidth),n.maxWidth);n.height=Math.min(Math.max(n.height,n.minHeight),n.maxHeight);n.width=Math.max(n.minWidth,n.width*r);n.height=Math.max(n.minHeight,n.height*r);n.left=i.left+(i.width-n.width)/2;n.top=i.top+(i.height-n.height)/2;n.oldLeft=n.left;n.oldTop=n.top;(this||t).initialCropBoxData=rt({},n)},limitCropBox:function limitCropBox(e,i){var a=(this||t).options,r=(this||t).containerData,n=(this||t).canvasData,o=(this||t).cropBoxData,s=(this||t).limited;var h=a.aspectRatio;if(e){var c=Number(a.minCropBoxWidth)||0;var l=Number(a.minCropBoxHeight)||0;var d=s?Math.min(r.width,n.width,n.width+n.left,r.width-n.left):r.width;var p=s?Math.min(r.height,n.height,n.height+n.top,r.height-n.top):r.height;c=Math.min(c,r.width);l=Math.min(l,r.height);if(h){c&&l?l*h>c?l=c/h:c=l*h:c?l=c/h:l&&(c=l*h);p*h>d?p=d/h:d=p*h}o.minWidth=Math.min(c,d);o.minHeight=Math.min(l,p);o.maxWidth=d;o.maxHeight=p}if(i)if(s){o.minLeft=Math.max(0,n.left);o.minTop=Math.max(0,n.top);o.maxLeft=Math.min(r.width,n.left+n.width)-o.width;o.maxTop=Math.min(r.height,n.top+n.height)-o.height}else{o.minLeft=0;o.minTop=0;o.maxLeft=r.width-o.width;o.maxTop=r.height-o.height}},renderCropBox:function renderCropBox(){var e=(this||t).options,i=(this||t).containerData,a=(this||t).cropBoxData;(a.width>a.maxWidth||a.width<a.minWidth)&&(a.left=a.oldLeft);(a.height>a.maxHeight||a.height<a.minHeight)&&(a.top=a.oldTop);a.width=Math.min(Math.max(a.width,a.minWidth),a.maxWidth);a.height=Math.min(Math.max(a.height,a.minHeight),a.maxHeight);this.limitCropBox(false,true);a.left=Math.min(Math.max(a.left,a.minLeft),a.maxLeft);a.top=Math.min(Math.max(a.top,a.minTop),a.maxTop);a.oldLeft=a.left;a.oldTop=a.top;e.movable&&e.cropBoxMovable&&setData((this||t).face,N,a.width>=i.width&&a.height>=i.height?h:o);setStyle((this||t).cropBox,rt({width:a.width,height:a.height},getTransforms({translateX:a.left,translateY:a.top})));(this||t).cropped&&(this||t).limited&&this.limitCanvas(true,true);(this||t).disabled||this.output()},output:function output(){this.preview();dispatchEvent((this||t).element,B,this.getData())}};var vt={initPreview:function initPreview(){var e=(this||t).element,i=(this||t).crossOrigin;var a=(this||t).options.preview;var r=i?(this||t).crossOriginUrl:(this||t).url;var n=e.alt||"The image to preview";var o=document.createElement("img");i&&(o.crossOrigin=i);o.src=r;o.alt=n;(this||t).viewBox.appendChild(o);(this||t).viewBoxImage=o;if(a){var s=a;typeof a==="string"?s=e.ownerDocument.querySelectorAll(a):a.querySelector&&(s=[a]);(this||t).previews=s;forEach(s,(function(t){var e=document.createElement("img");setData(t,O,{width:t.offsetWidth,height:t.offsetHeight,html:t.innerHTML});i&&(e.crossOrigin=i);e.src=r;e.alt=n;e.style.cssText='display:block;width:100%;height:auto;min-width:0!important;min-height:0!important;max-width:none!important;max-height:none!important;image-orientation:0deg!important;"';t.innerHTML="";t.appendChild(e)}))}},resetPreview:function resetPreview(){forEach((this||t).previews,(function(t){var e=getData(t,O);setStyle(t,{width:e.width,height:e.height});t.innerHTML=e.html;removeData(t,O)}))},preview:function preview(){var e=(this||t).imageData,i=(this||t).canvasData,a=(this||t).cropBoxData;var r=a.width,n=a.height;var o=e.width,s=e.height;var h=a.left-i.left-e.left;var c=a.top-i.top-e.top;if((this||t).cropped&&!(this||t).disabled){setStyle((this||t).viewBoxImage,rt({width:o,height:s},getTransforms(rt({translateX:-h,translateY:-c},e))));forEach((this||t).previews,(function(t){var i=getData(t,O);var a=i.width;var l=i.height;var d=a;var p=l;var u=1;if(r){u=a/r;p=n*u}if(n&&p>l){u=l/n;d=r*u;p=l}setStyle(t,{width:d,height:p});setStyle(t.getElementsByTagName("img")[0],rt({width:o*u,height:s*u},getTransforms(rt({translateX:-h*u,translateY:-c*u},e))))}))}}};var mt={bind:function bind(){var e=(this||t).element,i=(this||t).options,a=(this||t).cropper;isFunction(i.cropstart)&&addListener(e,z,i.cropstart);isFunction(i.cropmove)&&addListener(e,S,i.cropmove);isFunction(i.cropend)&&addListener(e,k,i.cropend);isFunction(i.crop)&&addListener(e,B,i.crop);isFunction(i.zoom)&&addListener(e,U,i.zoom);addListener(a,H,(this||t).onCropStart=(this||t).cropStart.bind(this||t));i.zoomable&&i.zoomOnWheel&&addListener(a,_,(this||t).onWheel=(this||t).wheel.bind(this||t),{passive:false,capture:true});i.toggleDragModeOnDblclick&&addListener(a,A,(this||t).onDblclick=(this||t).dblclick.bind(this||t));addListener(e.ownerDocument,R,(this||t).onCropMove=(this||t).cropMove.bind(this||t));addListener(e.ownerDocument,Y,(this||t).onCropEnd=(this||t).cropEnd.bind(this||t));i.responsive&&addListener(window,I,(this||t).onResize=(this||t).resize.bind(this||t))},unbind:function unbind(){var e=(this||t).element,i=(this||t).options,a=(this||t).cropper;isFunction(i.cropstart)&&removeListener(e,z,i.cropstart);isFunction(i.cropmove)&&removeListener(e,S,i.cropmove);isFunction(i.cropend)&&removeListener(e,k,i.cropend);isFunction(i.crop)&&removeListener(e,B,i.crop);isFunction(i.zoom)&&removeListener(e,U,i.zoom);removeListener(a,H,(this||t).onCropStart);i.zoomable&&i.zoomOnWheel&&removeListener(a,_,(this||t).onWheel,{passive:false,capture:true});i.toggleDragModeOnDblclick&&removeListener(a,A,(this||t).onDblclick);removeListener(e.ownerDocument,R,(this||t).onCropMove);removeListener(e.ownerDocument,Y,(this||t).onCropEnd);i.responsive&&removeListener(window,I,(this||t).onResize)}};var gt={resize:function resize(){if(!(this||t).disabled){var e=(this||t).options,i=(this||t).container,a=(this||t).containerData;var r=i.offsetWidth/a.width;var n=i.offsetHeight/a.height;var o=Math.abs(r-1)>Math.abs(n-1)?r:n;if(o!==1){var s;var h;if(e.restore){s=this.getCanvasData();h=this.getCropBoxData()}this.render();if(e.restore){this.setCanvasData(forEach(s,(function(t,e){s[e]=t*o})));this.setCropBoxData(forEach(h,(function(t,e){h[e]=t*o})))}}}},dblclick:function dblclick(){(this||t).disabled||(this||t).options.dragMode===L||this.setDragMode(hasClass((this||t).dragBox,b)?T:E)},wheel:function wheel(e){var i=this||t;var a=Number((this||t).options.wheelZoomRatio)||.1;var r=1;if(!(this||t).disabled){e.preventDefault();if(!(this||t).wheeling){(this||t).wheeling=true;setTimeout((function(){i.wheeling=false}),50);e.deltaY?r=e.deltaY>0?1:-1:e.wheelDelta?r=-e.wheelDelta/120:e.detail&&(r=e.detail>0?1:-1);this.zoom(-r*a,e)}}},cropStart:function cropStart(e){var i=e.buttons,a=e.button;if(!((this||t).disabled||(e.type==="mousedown"||e.type==="pointerdown"&&e.pointerType==="mouse")&&(isNumber(i)&&i!==1||isNumber(a)&&a!==0||e.ctrlKey))){var r=(this||t).options,n=(this||t).pointers;var o;e.changedTouches?forEach(e.changedTouches,(function(t){n[t.identifier]=getPointer(t)})):n[e.pointerId||0]=getPointer(e);o=Object.keys(n).length>1&&r.zoomable&&r.zoomOnTouch?c:getData(e.target,N);if(q.test(o)&&dispatchEvent((this||t).element,z,{originalEvent:e,action:o})!==false){e.preventDefault();(this||t).action=o;(this||t).cropping=false;if(o===s){(this||t).cropping=true;addClass((this||t).dragBox,D)}}}},cropMove:function cropMove(e){var i=(this||t).action;if(!(this||t).disabled&&i){var a=(this||t).pointers;e.preventDefault();if(dispatchEvent((this||t).element,S,{originalEvent:e,action:i})!==false){e.changedTouches?forEach(e.changedTouches,(function(t){rt(a[t.identifier]||{},getPointer(t,true))})):rt(a[e.pointerId||0]||{},getPointer(e,true));this.change(e)}}},cropEnd:function cropEnd(e){if(!(this||t).disabled){var i=(this||t).action,a=(this||t).pointers;e.changedTouches?forEach(e.changedTouches,(function(t){delete a[t.identifier]})):delete a[e.pointerId||0];if(i){e.preventDefault();Object.keys(a).length||((this||t).action="");if((this||t).cropping){(this||t).cropping=false;toggleClass((this||t).dragBox,D,(this||t).cropped&&(this||t).options.modal)}dispatchEvent((this||t).element,k,{originalEvent:e,action:i})}}}};var bt={change:function change(e){var i=(this||t).options,a=(this||t).canvasData,r=(this||t).containerData,n=(this||t).cropBoxData,b=(this||t).pointers;var w=(this||t).action;var x=i.aspectRatio;var C=n.left,D=n.top,M=n.width,N=n.height;var O=C+M;var E=D+N;var T=0;var L=0;var B=r.width;var k=r.height;var S=true;var z;!x&&e.shiftKey&&(x=M&&N?M/N:1);if((this||t).limited){T=n.minLeft;L=n.minTop;B=T+Math.min(r.width,a.width,a.left+a.width);k=L+Math.min(r.height,a.height,a.top+a.height)}var A=b[Object.keys(b)[0]];var j={x:A.endX-A.startX,y:A.endY-A.startY};var W=function check(t){switch(t){case l:O+j.x>B&&(j.x=B-O);break;case d:C+j.x<T&&(j.x=T-C);break;case u:D+j.y<L&&(j.y=L-D);break;case p:E+j.y>k&&(j.y=k-E);break}};switch(w){case o:C+=j.x;D+=j.y;break;case l:if(j.x>=0&&(O>=B||x&&(D<=L||E>=k))){S=false;break}W(l);M+=j.x;if(M<0){w=d;M=-M;C-=M}if(x){N=M/x;D+=(n.height-N)/2}break;case u:if(j.y<=0&&(D<=L||x&&(C<=T||O>=B))){S=false;break}W(u);N-=j.y;D+=j.y;if(N<0){w=p;N=-N;D-=N}if(x){M=N*x;C+=(n.width-M)/2}break;case d:if(j.x<=0&&(C<=T||x&&(D<=L||E>=k))){S=false;break}W(d);M-=j.x;C+=j.x;if(M<0){w=l;M=-M;C-=M}if(x){N=M/x;D+=(n.height-N)/2}break;case p:if(j.y>=0&&(E>=k||x&&(C<=T||O>=B))){S=false;break}W(p);N+=j.y;if(N<0){w=u;N=-N;D-=N}if(x){M=N*x;C+=(n.width-M)/2}break;case f:if(x){if(j.y<=0&&(D<=L||O>=B)){S=false;break}W(u);N-=j.y;D+=j.y;M=N*x}else{W(u);W(l);j.x>=0?O<B?M+=j.x:j.y<=0&&D<=L&&(S=false):M+=j.x;if(j.y<=0){if(D>L){N-=j.y;D+=j.y}}else{N-=j.y;D+=j.y}}if(M<0&&N<0){w=g;N=-N;M=-M;D-=N;C-=M}else if(M<0){w=v;M=-M;C-=M}else if(N<0){w=m;N=-N;D-=N}break;case v:if(x){if(j.y<=0&&(D<=L||C<=T)){S=false;break}W(u);N-=j.y;D+=j.y;M=N*x;C+=n.width-M}else{W(u);W(d);if(j.x<=0)if(C>T){M-=j.x;C+=j.x}else j.y<=0&&D<=L&&(S=false);else{M-=j.x;C+=j.x}if(j.y<=0){if(D>L){N-=j.y;D+=j.y}}else{N-=j.y;D+=j.y}}if(M<0&&N<0){w=m;N=-N;M=-M;D-=N;C-=M}else if(M<0){w=f;M=-M;C-=M}else if(N<0){w=g;N=-N;D-=N}break;case g:if(x){if(j.x<=0&&(C<=T||E>=k)){S=false;break}W(d);M-=j.x;C+=j.x;N=M/x}else{W(p);W(d);if(j.x<=0)if(C>T){M-=j.x;C+=j.x}else j.y>=0&&E>=k&&(S=false);else{M-=j.x;C+=j.x}j.y>=0?E<k&&(N+=j.y):N+=j.y}if(M<0&&N<0){w=f;N=-N;M=-M;D-=N;C-=M}else if(M<0){w=m;M=-M;C-=M}else if(N<0){w=v;N=-N;D-=N}break;case m:if(x){if(j.x>=0&&(O>=B||E>=k)){S=false;break}W(l);M+=j.x;N=M/x}else{W(p);W(l);j.x>=0?O<B?M+=j.x:j.y>=0&&E>=k&&(S=false):M+=j.x;j.y>=0?E<k&&(N+=j.y):N+=j.y}if(M<0&&N<0){w=v;N=-N;M=-M;D-=N;C-=M}else if(M<0){w=g;M=-M;C-=M}else if(N<0){w=f;N=-N;D-=N}break;case h:this.move(j.x,j.y);S=false;break;case c:this.zoom(getMaxZoomRatio(b),e);S=false;break;case s:if(!j.x||!j.y){S=false;break}z=getOffset((this||t).cropper);C=A.startX-z.left;D=A.startY-z.top;M=n.minWidth;N=n.minHeight;if(j.x>0)w=j.y>0?m:f;else if(j.x<0){C-=M;w=j.y>0?g:v}j.y<0&&(D-=N);if(!(this||t).cropped){removeClass((this||t).cropBox,y);(this||t).cropped=true;(this||t).limited&&this.limitCropBox(true,true)}break}if(S){n.width=M;n.height=N;n.left=C;n.top=D;(this||t).action=w;this.renderCropBox()}forEach(b,(function(t){t.startX=t.endX;t.startY=t.endY}))}};var wt={crop:function crop(){if((this||t).ready&&!(this||t).cropped&&!(this||t).disabled){(this||t).cropped=true;this.limitCropBox(true,true);(this||t).options.modal&&addClass((this||t).dragBox,D);removeClass((this||t).cropBox,y);this.setCropBoxData((this||t).initialCropBoxData)}return this||t},reset:function reset(){if((this||t).ready&&!(this||t).disabled){(this||t).imageData=rt({},(this||t).initialImageData);(this||t).canvasData=rt({},(this||t).initialCanvasData);(this||t).cropBoxData=rt({},(this||t).initialCropBoxData);this.renderCanvas();(this||t).cropped&&this.renderCropBox()}return this||t},clear:function clear(){if((this||t).cropped&&!(this||t).disabled){rt((this||t).cropBoxData,{left:0,top:0,width:0,height:0});(this||t).cropped=false;this.renderCropBox();this.limitCanvas(true,true);this.renderCanvas();removeClass((this||t).dragBox,D);addClass((this||t).cropBox,y)}return this||t},
/**
     * Replace the image's src and rebuild the cropper
     * @param {string} url - The new URL.
     * @param {boolean} [hasSameSize] - Indicate if the new image has the same size as the old one.
     * @returns {Cropper} this
     */
replace:function replace(e){var i=arguments.length>1&&arguments[1]!==void 0&&arguments[1];if(!(this||t).disabled&&e){(this||t).isImg&&((this||t).element.src=e);if(i){(this||t).url=e;(this||t).image.src=e;if((this||t).ready){(this||t).viewBoxImage.src=e;forEach((this||t).previews,(function(t){t.getElementsByTagName("img")[0].src=e}))}}else{(this||t).isImg&&((this||t).replaced=true);(this||t).options.data=null;this.uncreate();this.load(e)}}return this||t},enable:function enable(){if((this||t).ready&&(this||t).disabled){(this||t).disabled=false;removeClass((this||t).cropper,w)}return this||t},disable:function disable(){if((this||t).ready&&!(this||t).disabled){(this||t).disabled=true;addClass((this||t).cropper,w)}return this||t},
/**
     * Destroy the cropper and remove the instance from the image
     * @returns {Cropper} this
     */
destroy:function destroy(){var e=(this||t).element;if(!e[n])return this||t;e[n]=void 0;(this||t).isImg&&(this||t).replaced&&(e.src=(this||t).originalUrl);this.uncreate();return this||t},
/**
     * Move the canvas with relative offsets
     * @param {number} offsetX - The relative offset distance on the x-axis.
     * @param {number} [offsetY=offsetX] - The relative offset distance on the y-axis.
     * @returns {Cropper} this
     */
move:function move(e){var i=arguments.length>1&&arguments[1]!==void 0?arguments[1]:e;var a=(this||t).canvasData,r=a.left,n=a.top;return this.moveTo(isUndefined(e)?e:r+Number(e),isUndefined(i)?i:n+Number(i))},
/**
     * Move the canvas to an absolute point
     * @param {number} x - The x-axis coordinate.
     * @param {number} [y=x] - The y-axis coordinate.
     * @returns {Cropper} this
     */
moveTo:function moveTo(e){var i=arguments.length>1&&arguments[1]!==void 0?arguments[1]:e;var a=(this||t).canvasData;var r=false;e=Number(e);i=Number(i);if((this||t).ready&&!(this||t).disabled&&(this||t).options.movable){if(isNumber(e)){a.left=e;r=true}if(isNumber(i)){a.top=i;r=true}r&&this.renderCanvas(true)}return this||t},
/**
     * Zoom the canvas with a relative ratio
     * @param {number} ratio - The target ratio.
     * @param {Event} _originalEvent - The original event if any.
     * @returns {Cropper} this
     */
zoom:function zoom(e,i){var a=(this||t).canvasData;e=Number(e);e=e<0?1/(1-e):1+e;return this.zoomTo(a.width*e/a.naturalWidth,null,i)},
/**
     * Zoom the canvas to an absolute ratio
     * @param {number} ratio - The target ratio.
     * @param {Object} pivot - The zoom pivot point coordinate.
     * @param {Event} _originalEvent - The original event if any.
     * @returns {Cropper} this
     */
zoomTo:function zoomTo(e,i,a){var r=(this||t).options,n=(this||t).canvasData;var o=n.width,s=n.height,h=n.naturalWidth,c=n.naturalHeight;e=Number(e);if(e>=0&&(this||t).ready&&!(this||t).disabled&&r.zoomable){var l=h*e;var d=c*e;if(dispatchEvent((this||t).element,U,{ratio:e,oldRatio:o/h,originalEvent:a})===false)return this||t;if(a){var p=(this||t).pointers;var u=getOffset((this||t).cropper);var f=p&&Object.keys(p).length?getPointersCenter(p):{pageX:a.pageX,pageY:a.pageY};n.left-=(l-o)*((f.pageX-u.left-n.left)/o);n.top-=(d-s)*((f.pageY-u.top-n.top)/s)}else if(isPlainObject(i)&&isNumber(i.x)&&isNumber(i.y)){n.left-=(l-o)*((i.x-n.left)/o);n.top-=(d-s)*((i.y-n.top)/s)}else{n.left-=(l-o)/2;n.top-=(d-s)/2}n.width=l;n.height=d;this.renderCanvas(true)}return this||t},
/**
     * Rotate the canvas with a relative degree
     * @param {number} degree - The rotate degree.
     * @returns {Cropper} this
     */
rotate:function rotate(e){return this.rotateTo(((this||t).imageData.rotate||0)+Number(e))},
/**
     * Rotate the canvas to an absolute degree
     * @param {number} degree - The rotate degree.
     * @returns {Cropper} this
     */
rotateTo:function rotateTo(e){e=Number(e);if(isNumber(e)&&(this||t).ready&&!(this||t).disabled&&(this||t).options.rotatable){(this||t).imageData.rotate=e%360;this.renderCanvas(true,true)}return this||t},
/**
     * Scale the image on the x-axis.
     * @param {number} scaleX - The scale ratio on the x-axis.
     * @returns {Cropper} this
     */
scaleX:function scaleX(e){var i=(this||t).imageData.scaleY;return this.scale(e,isNumber(i)?i:1)},
/**
     * Scale the image on the y-axis.
     * @param {number} scaleY - The scale ratio on the y-axis.
     * @returns {Cropper} this
     */
scaleY:function scaleY(e){var i=(this||t).imageData.scaleX;return this.scale(isNumber(i)?i:1,e)},
/**
     * Scale the image
     * @param {number} scaleX - The scale ratio on the x-axis.
     * @param {number} [scaleY=scaleX] - The scale ratio on the y-axis.
     * @returns {Cropper} this
     */
scale:function scale(e){var i=arguments.length>1&&arguments[1]!==void 0?arguments[1]:e;var a=(this||t).imageData;var r=false;e=Number(e);i=Number(i);if((this||t).ready&&!(this||t).disabled&&(this||t).options.scalable){if(isNumber(e)){a.scaleX=e;r=true}if(isNumber(i)){a.scaleY=i;r=true}r&&this.renderCanvas(true,true)}return this||t},
/**
     * Get the cropped area position and size data (base on the original image)
     * @param {boolean} [rounded=false] - Indicate if round the data values or not.
     * @returns {Object} The result cropped data.
     */
getData:function getData(){var e=arguments.length>0&&arguments[0]!==void 0&&arguments[0];var i=(this||t).options,a=(this||t).imageData,r=(this||t).canvasData,n=(this||t).cropBoxData;var o;if((this||t).ready&&(this||t).cropped){o={x:n.left-r.left,y:n.top-r.top,width:n.width,height:n.height};var s=a.width/a.naturalWidth;forEach(o,(function(t,e){o[e]=t/s}));if(e){var h=Math.round(o.y+o.height);var c=Math.round(o.x+o.width);o.x=Math.round(o.x);o.y=Math.round(o.y);o.width=c-o.x;o.height=h-o.y}}else o={x:0,y:0,width:0,height:0};i.rotatable&&(o.rotate=a.rotate||0);if(i.scalable){o.scaleX=a.scaleX||1;o.scaleY=a.scaleY||1}return o},
/**
     * Set the cropped area position and size with new data
     * @param {Object} data - The new data.
     * @returns {Cropper} this
     */
setData:function setData(e){var i=(this||t).options,a=(this||t).imageData,r=(this||t).canvasData;var n={};if((this||t).ready&&!(this||t).disabled&&isPlainObject(e)){var o=false;if(i.rotatable&&isNumber(e.rotate)&&e.rotate!==a.rotate){a.rotate=e.rotate;o=true}if(i.scalable){if(isNumber(e.scaleX)&&e.scaleX!==a.scaleX){a.scaleX=e.scaleX;o=true}if(isNumber(e.scaleY)&&e.scaleY!==a.scaleY){a.scaleY=e.scaleY;o=true}}o&&this.renderCanvas(true,true);var s=a.width/a.naturalWidth;isNumber(e.x)&&(n.left=e.x*s+r.left);isNumber(e.y)&&(n.top=e.y*s+r.top);isNumber(e.width)&&(n.width=e.width*s);isNumber(e.height)&&(n.height=e.height*s);this.setCropBoxData(n)}return this||t},
/**
     * Get the container size data.
     * @returns {Object} The result container data.
     */
getContainerData:function getContainerData(){return(this||t).ready?rt({},(this||t).containerData):{}},
/**
     * Get the image position and size data.
     * @returns {Object} The result image data.
     */
getImageData:function getImageData(){return(this||t).sized?rt({},(this||t).imageData):{}},
/**
     * Get the canvas position and size data.
     * @returns {Object} The result canvas data.
     */
getCanvasData:function getCanvasData(){var e=(this||t).canvasData;var i={};(this||t).ready&&forEach(["left","top","width","height","naturalWidth","naturalHeight"],(function(t){i[t]=e[t]}));return i},
/**
     * Set the canvas position and size with new data.
     * @param {Object} data - The new canvas data.
     * @returns {Cropper} this
     */
setCanvasData:function setCanvasData(e){var i=(this||t).canvasData;var a=i.aspectRatio;if((this||t).ready&&!(this||t).disabled&&isPlainObject(e)){isNumber(e.left)&&(i.left=e.left);isNumber(e.top)&&(i.top=e.top);if(isNumber(e.width)){i.width=e.width;i.height=e.width/a}else if(isNumber(e.height)){i.height=e.height;i.width=e.height*a}this.renderCanvas(true)}return this||t},
/**
     * Get the crop box position and size data.
     * @returns {Object} The result crop box data.
     */
getCropBoxData:function getCropBoxData(){var e=(this||t).cropBoxData;var i;(this||t).ready&&(this||t).cropped&&(i={left:e.left,top:e.top,width:e.width,height:e.height});return i||{}},
/**
     * Set the crop box position and size with new data.
     * @param {Object} data - The new crop box data.
     * @returns {Cropper} this
     */
setCropBoxData:function setCropBoxData(e){var i=(this||t).cropBoxData;var a=(this||t).options.aspectRatio;var r;var n;if((this||t).ready&&(this||t).cropped&&!(this||t).disabled&&isPlainObject(e)){isNumber(e.left)&&(i.left=e.left);isNumber(e.top)&&(i.top=e.top);if(isNumber(e.width)&&e.width!==i.width){r=true;i.width=e.width}if(isNumber(e.height)&&e.height!==i.height){n=true;i.height=e.height}a&&(r?i.height=i.width/a:n&&(i.width=i.height*a));this.renderCropBox()}return this||t},
/**
     * Get a canvas drawn the cropped image.
     * @param {Object} [options={}] - The config options.
     * @returns {HTMLCanvasElement} - The result canvas.
     */
getCroppedCanvas:function getCroppedCanvas(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{};if(!(this||t).ready||!window.HTMLCanvasElement)return null;var i=(this||t).canvasData;var a=getSourceCanvas((this||t).image,(this||t).imageData,i,e);if(!(this||t).cropped)return a;var r=this.getData(e.rounded),n=r.x,o=r.y,s=r.width,h=r.height;var c=a.width/Math.floor(i.naturalWidth);if(c!==1){n*=c;o*=c;s*=c;h*=c}var l=s/h;var d=getAdjustedSizes({aspectRatio:l,width:e.maxWidth||Infinity,height:e.maxHeight||Infinity});var p=getAdjustedSizes({aspectRatio:l,width:e.minWidth||0,height:e.minHeight||0},"cover");var u=getAdjustedSizes({aspectRatio:l,width:e.width||(c!==1?a.width:s),height:e.height||(c!==1?a.height:h)}),f=u.width,v=u.height;f=Math.min(d.width,Math.max(p.width,f));v=Math.min(d.height,Math.max(p.height,v));var m=document.createElement("canvas");var g=m.getContext("2d");m.width=normalizeDecimalNumber(f);m.height=normalizeDecimalNumber(v);g.fillStyle=e.fillColor||"transparent";g.fillRect(0,0,f,v);var b=e.imageSmoothingEnabled,w=b===void 0||b,y=e.imageSmoothingQuality;g.imageSmoothingEnabled=w;y&&(g.imageSmoothingQuality=y);var x=a.width;var C=a.height;var D=n;var M=o;var N;var O;var E;var T;var L;var B;if(D<=-s||D>x){D=0;N=0;E=0;L=0}else if(D<=0){E=-D;D=0;N=Math.min(x,s+D);L=N}else if(D<=x){E=0;N=Math.min(s,x-D);L=N}if(N<=0||M<=-h||M>C){M=0;O=0;T=0;B=0}else if(M<=0){T=-M;M=0;O=Math.min(C,h+M);B=O}else if(M<=C){T=0;O=Math.min(h,C-M);B=O}var k=[D,M,N,O];if(L>0&&B>0){var S=f/s;k.push(E*S,T*S,L*S,B*S)}g.drawImage.apply(g,[a].concat(_toConsumableArray(k.map((function(t){return Math.floor(normalizeDecimalNumber(t))})))));return m},
/**
     * Change the aspect ratio of the crop box.
     * @param {number} aspectRatio - The new aspect ratio.
     * @returns {Cropper} this
     */
setAspectRatio:function setAspectRatio(e){var i=(this||t).options;if(!(this||t).disabled&&!isUndefined(e)){i.aspectRatio=Math.max(0,e)||NaN;if((this||t).ready){this.initCropBox();(this||t).cropped&&this.renderCropBox()}}return this||t},
/**
     * Change the drag mode.
     * @param {string} mode - The new drag mode.
     * @returns {Cropper} this
     */
setDragMode:function setDragMode(e){var i=(this||t).options,a=(this||t).dragBox,r=(this||t).face;if((this||t).ready&&!(this||t).disabled){var n=e===E;var o=i.movable&&e===T;e=n||o?e:L;i.dragMode=e;setData(a,N,e);toggleClass(a,b,n);toggleClass(a,M,o);if(!i.cropBoxMovable){setData(r,N,e);toggleClass(r,b,n);toggleClass(r,M,o)}}return this||t}};var yt=i.Cropper;var xt=function(){
/**
     * Create a new Cropper.
     * @param {Element} element - The target element for cropping.
     * @param {Object} [options={}] - The configuration options.
     */
function Cropper(e){var i=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};_classCallCheck(this||t,Cropper);if(!e||!Z.test(e.tagName))throw new Error("The first argument is required and must be an <img> or <canvas> element.");(this||t).element=e;(this||t).options=rt({},V,isPlainObject(i)&&i);(this||t).cropped=false;(this||t).disabled=false;(this||t).pointers={};(this||t).ready=false;(this||t).reloading=false;(this||t).replaced=false;(this||t).sized=false;(this||t).sizing=false;this.init()}return _createClass(Cropper,[{key:"init",value:function init(){var e=(this||t).element;var i=e.tagName.toLowerCase();var a;if(!e[n]){e[n]=this||t;if(i==="img"){(this||t).isImg=true;a=e.getAttribute("src")||"";(this||t).originalUrl=a;if(!a)return;a=e.src}else i==="canvas"&&window.HTMLCanvasElement&&(a=e.toDataURL());this.load(a)}}},{key:"load",value:function load(e){var i=this||t;if(e){(this||t).url=e;(this||t).imageData={};var a=(this||t).element,r=(this||t).options;r.rotatable||r.scalable||(r.checkOrientation=false);if(r.checkOrientation&&window.ArrayBuffer)if(K.test(e))$.test(e)?this.read(dataURLToArrayBuffer(e)):this.clone();else{var n=new XMLHttpRequest;var o=(this||t).clone.bind(this||t);(this||t).reloading=true;(this||t).xhr=n;n.onabort=o;n.onerror=o;n.ontimeout=o;n.onprogress=function(){n.getResponseHeader("content-type")!==F&&n.abort()};n.onload=function(){i.read(n.response)};n.onloadend=function(){i.reloading=false;i.xhr=null};r.checkCrossOrigin&&isCrossOriginURL(e)&&a.crossOrigin&&(e=addTimestamp(e));n.open("GET",e,true);n.responseType="arraybuffer";n.withCredentials=a.crossOrigin==="use-credentials";n.send()}else this.clone()}}},{key:"read",value:function read(e){var i=(this||t).options,a=(this||t).imageData;var r=resetAndGetOrientation(e);var n=0;var o=1;var s=1;if(r>1){(this||t).url=arrayBufferToDataURL(e,F);var h=parseOrientation(r);n=h.rotate;o=h.scaleX;s=h.scaleY}i.rotatable&&(a.rotate=n);if(i.scalable){a.scaleX=o;a.scaleY=s}this.clone()}},{key:"clone",value:function clone(){var e=(this||t).element,i=(this||t).url;var a=e.crossOrigin;var r=i;if((this||t).options.checkCrossOrigin&&isCrossOriginURL(i)){a||(a="anonymous");r=addTimestamp(i)}(this||t).crossOrigin=a;(this||t).crossOriginUrl=r;var n=document.createElement("img");a&&(n.crossOrigin=a);n.src=r||i;n.alt=e.alt||"The image to crop";(this||t).image=n;n.onload=(this||t).start.bind(this||t);n.onerror=(this||t).stop.bind(this||t);addClass(n,x);e.parentNode.insertBefore(n,e.nextSibling)}},{key:"start",value:function start(){var e=this||t;var a=(this||t).image;a.onload=null;a.onerror=null;(this||t).sizing=true;var r=i.navigator&&/(?:iPad|iPhone|iPod).*?AppleWebKit/i.test(i.navigator.userAgent);var n=function done(t,i){rt(e.imageData,{naturalWidth:t,naturalHeight:i,aspectRatio:t/i});e.initialImageData=rt({},e.imageData);e.sizing=false;e.sized=true;e.build()};if(!a.naturalWidth||r){var o=document.createElement("img");var s=document.body||document.documentElement;(this||t).sizingImage=o;o.onload=function(){n(o.width,o.height);r||s.removeChild(o)};o.src=a.src;if(!r){o.style.cssText="left:0;max-height:none!important;max-width:none!important;min-height:0!important;min-width:0!important;opacity:0;position:absolute;top:0;z-index:-1;";s.appendChild(o)}}else n(a.naturalWidth,a.naturalHeight)}},{key:"stop",value:function stop(){var e=(this||t).image;e.onload=null;e.onerror=null;e.parentNode.removeChild(e);(this||t).image=null}},{key:"build",value:function build(){if((this||t).sized&&!(this||t).ready){var e=(this||t).element,i=(this||t).options,a=(this||t).image;var r=e.parentNode;var s=document.createElement("div");s.innerHTML=J;var h=s.querySelector(".".concat(n,"-container"));var c=h.querySelector(".".concat(n,"-canvas"));var l=h.querySelector(".".concat(n,"-drag-box"));var d=h.querySelector(".".concat(n,"-crop-box"));var p=d.querySelector(".".concat(n,"-face"));(this||t).container=r;(this||t).cropper=h;(this||t).canvas=c;(this||t).dragBox=l;(this||t).cropBox=d;(this||t).viewBox=h.querySelector(".".concat(n,"-view-box"));(this||t).face=p;c.appendChild(a);addClass(e,y);r.insertBefore(h,e.nextSibling);removeClass(a,x);this.initPreview();this.bind();i.initialAspectRatio=Math.max(0,i.initialAspectRatio)||NaN;i.aspectRatio=Math.max(0,i.aspectRatio)||NaN;i.viewMode=Math.max(0,Math.min(3,Math.round(i.viewMode)))||0;addClass(d,y);i.guides||addClass(d.getElementsByClassName("".concat(n,"-dashed")),y);i.center||addClass(d.getElementsByClassName("".concat(n,"-center")),y);i.background&&addClass(h,"".concat(n,"-bg"));i.highlight||addClass(p,C);if(i.cropBoxMovable){addClass(p,M);setData(p,N,o)}if(!i.cropBoxResizable){addClass(d.getElementsByClassName("".concat(n,"-line")),y);addClass(d.getElementsByClassName("".concat(n,"-point")),y)}this.render();(this||t).ready=true;this.setDragMode(i.dragMode);i.autoCrop&&this.crop();this.setData(i.data);isFunction(i.ready)&&addListener(e,X,i.ready,{once:true});dispatchEvent(e,X)}}},{key:"unbuild",value:function unbuild(){if((this||t).ready){(this||t).ready=false;this.unbind();this.resetPreview();var e=(this||t).cropper.parentNode;e&&e.removeChild((this||t).cropper);removeClass((this||t).element,y)}}},{key:"uncreate",value:function uncreate(){if((this||t).ready){this.unbuild();(this||t).ready=false;(this||t).cropped=false}else if((this||t).sizing){(this||t).sizingImage.onload=null;(this||t).sizing=false;(this||t).sized=false}else if((this||t).reloading){(this||t).xhr.onabort=null;(this||t).xhr.abort()}else(this||t).image&&this.stop()}
/**
       * Get the no conflict cropper class.
       * @returns {Cropper} The cropper class.
       */}],[{key:"noConflict",value:function noConflict(){window.Cropper=yt;return Cropper}
/**
       * Change the default options.
       * @param {Object} options - The new default options.
       */},{key:"setDefaults",value:function setDefaults(t){rt(V,isPlainObject(t)&&t)}}])}();rt(xt.prototype,ft,vt,mt,gt,bt,wt);return xt}));var i=e;export{i as default};

