---
title: 从源码角度看php自增和自减
date: 2016-05-06 20:18:14
categories: php
tags: [php , source , 源码]
---

### 自增和自减基础

学过编程语言的同学应该都可以随口说出 ++a 和 a++ 的区别，具体的区别如下：

| Example       | Name          | Effect                                 |
| ------------- |:-------------:| --------------------------------------:|
| ++`$`a          | Pre-increment | Increments $a by one, then returns $a. |
| `$`a++          | Post-increment| Returns $a, then increments $a by one. |
| --`$`a          | Pre-decrement	| Decrements $a by one, then returns $a. |
| `$`a--	        | Post-decrement| Returns $a, then decrements $a by one. |


++a 表示取 a 的地址，增加内存中 a 的值，然后把值放在寄存器中。
a++ 表示取 a 的地址，把 a 的值装入寄存器中，然后增加内存中 a 的值。

<!-- more -->


### php 中的递增和递减


* 官方文档:
[http://php.net/manual/zh/language.operators.increment.php](http://php.net/manual/zh/language.operators.increment.php)

在php中，通常情况下的递增和递减没什么特别，下面我们看一些特殊的递增和递减。


```
$a = NULL;	$a++;	//int 1                                  
$a = NULL;	$a--;	//null                            		        
$a = true;	$a++;	//true                            	
$a = true;	$a--;	//true                            	
$a = false;	$a++;	//false                            		
$a = false;	$a--;	//false                            			
```

> 从上面可以看出，php中递增和递减运算符不影响布尔值；递减NULL值没有效果，但是递增NULL值的结果为1。


```
$a = 'C';	$a++;	//string D                                
$a = 'C';	$a--;	//string C                                
$a = 'C2';	$a++;	//string C3                               
$a = 'C2';	$a--;	//string C2                               
$a = '2C';	$a++;	//string 2D                               
$a = '2C';	$a--;	//string 2C                               
```

> 从上面可以看出，在php中，字符串支持递增，但是不支持递减。

再看一下下面的代码：


```
$a = 'Z';	$a++;	//string AA                               
$a = 'C9';	$a++;	//string D0                               
```

‘A'执行递增，结果为’B'；‘Z'执行递增，结果为’AA‘,'C9'递增，结果为'D0'。这和Perl相似。

### php源码分析:`$`a++与++`$`a


首先说明一下，此处的分析基于 php5.6 的源码分析。

对于前缀自增(++$a)，包含的opcode为PRE_INC，其最终调用的是Zend/zend_vm_execute.h文件中的ZEND_PRE_INC_SPEC_CV_HANDLER函数，源码如下：


```
static int ZEND_FASTCALL  ZEND_PRE_INC_SPEC_CV_HANDLER(ZEND_OPCODE_HANDLER_ARGS)
{
    USE_OPLINE
    zval **var_ptr;
    
    SAVE_OPLINE();
    var_ptr = _get_zval_ptr_ptr_cv_BP_VAR_RW(execute_data, opline->op1.var TSRMLS_CC);
    
    if (IS_CV == IS_VAR && UNEXPECTED(var_ptr == NULL)) {
        zend_error_noreturn(E_ERROR, "Cannot increment/decrement overloaded objects nor string offsets");
    }
    if (IS_CV == IS_VAR && UNEXPECTED(*var_ptr == &EG(error_zval))) {
        if (RETURN_VALUE_USED(opline)) {
            PZVAL_LOCK(&EG(uninitialized_zval));
            EX_T(opline->result.var).var.ptr = &EG(uninitialized_zval);
        }
    
        CHECK_EXCEPTION();
        ZEND_VM_NEXT_OPCODE();
    }
    
    SEPARATE_ZVAL_IF_NOT_REF(var_ptr);
    
    if (UNEXPECTED(Z_TYPE_PP(var_ptr) == IS_OBJECT)
       && Z_OBJ_HANDLER_PP(var_ptr, get)
       && Z_OBJ_HANDLER_PP(var_ptr, set)) {
        /* proxy object */
        zval *val = Z_OBJ_HANDLER_PP(var_ptr, get)(*var_ptr TSRMLS_CC);
        Z_ADDREF_P(val);
        fast_increment_function(val);
        Z_OBJ_HANDLER_PP(var_ptr, set)(var_ptr, val TSRMLS_CC);
        zval_ptr_dtor(&val);
    } else {
        fast_increment_function(*var_ptr);
    }
    
    if (RETURN_VALUE_USED(opline)) {
        PZVAL_LOCK(*var_ptr);
        EX_T(opline->result.var).var.ptr = *var_ptr;
    }
    
    CHECK_EXCEPTION();
    ZEND_VM_NEXT_OPCODE();
}
```

fast_increment_function函数实际调用的是increment_function函数：

```
ZEND_API int increment_function(zval op1) 
{
    switch (Z_TYPE_P(op1)) {
        case IS_LONG:
            if (Z_LVAL_P(op1) == LONG_MAX) {
                /* switch to double */
                double d = (double)Z_LVAL_P(op1);
                ZVAL_DOUBLE(op1, d+1);
            } else {
            Z_LVAL_P(op1)++;
            }
            break;
        case IS_DOUBLE:
            Z_DVAL_P(op1) = Z_DVAL_P(op1) + 1;
            break;
        case IS_NULL:
            ZVAL_LONG(op1, 1);
            break;
        case IS_STRING: {
                long lval;
                double dval;
    
            switch (is_numeric_string(Z_STRVAL_P(op1), Z_STRLEN_P(op1), &lval, &dval, 0)) {
                    case IS_LONG:
                        str_efree(Z_STRVAL_P(op1));
                        if (lval == LONG_MAX) {
                            /* switch to double */
                            double d = (double)lval;
                            ZVAL_DOUBLE(op1, d+1);
                        } else {
                            ZVAL_LONG(op1, lval+1);
                        }
                        break;
                    case IS_DOUBLE:
                        str_efree(Z_STRVAL_P(op1));
                        ZVAL_DOUBLE(op1, dval+1);
                        break;
                    default:
                        /* Perl style string increment */
                        increment_string(op1);
                        break;
                }
            }
            break;
        case IS_OBJECT:
            if (Z_OBJ_HANDLER_P(op1, do_operation)) {
                zval *op2;
                int res;
                TSRMLS_FETCH();
    
                MAKE_STD_ZVAL(op2);
                ZVAL_LONG(op2, 1);
            res = Z_OBJ_HANDLER_P(op1, do_operation)(ZEND_ADD, op1, op1, op2 TSRMLS_CC);
                zval_ptr_dtor(&op2);
    
                return res;
            }
            return FAILURE;
        default:
            return FAILURE;
    }
    return SUCCESS;
}
```

首先调用_get_zval_ptr_ptr_cv_BP_VAR_RW函数获取CV(Compiled variable)类型变量；                                           
其次会调用fast_increment_function函数，再调用increment_function函数，实现变量的增加操作，
在increment_function函数中，会根据变量的类型来进行对应的操作，从上面可以看出，依次判断的类型有IS_LONG/IS_DOUBLE/IS_NULL/IS_STRING/IS_OBJECT。                                                                                  	
如果是IS_LONG类型，若变量达到long的最大值，则将其转化为double类型后加1，否则直接加1；             
如果是IS_DOUBLE类型，则直接加1；                                                                                                                  
如果是IS_NULL类型，则会调用宏ZVAL_LONG(op1, 1)，直接返回long类型的1；                                                                         
如果是IS_STRING类型，则会先将其转化为数字类型，然后再根据上面判断数字类型的逻辑判断；

如果是IS_OBJECT类型，并且其内部定义了运算符操作的实现，那就调用这个handler来处理,进行                                                                                    
                                                                                   
> 简言之，前缀自增实际上操作的是变量本身，在表达式中使用的也是变量本身。


对于后缀自增($a++)，包含的opcode为POST_INC，其最终调用的是Zend/zend_vm_execute.h文件中的ZEND_POST_INC_SPEC_CV_HANDLER函数，源码如下：


```
static int ZEND_FASTCALL  ZEND_POST_INC_SPEC_CV_HANDLER(ZEND_OPCODE_HANDLER_ARGS)
{
    USE_OPLINE
    zval **var_ptr, *retval;
    
    SAVE_OPLINE();
    var_ptr = _get_zval_ptr_ptr_cv_BP_VAR_RW(execute_data, opline->op1.var TSRMLS_CC);
    if (IS_CV == IS_VAR && UNEXPECTED(var_ptr == NULL)) {
        zend_error_noreturn(E_ERROR, "Cannot increment/decrement overloaded objects nor string offsets");
    }
    if (IS_CV == IS_VAR && UNEXPECTED(*var_ptr == &EG(error_zval))) {
        ZVAL_NULL(&EX_T(opline->result.var).tmp_var);
    
        CHECK_EXCEPTION();
        ZEND_VM_NEXT_OPCODE();
    }
    
    retval = &EX_T(opline->result.var).tmp_var;
    ZVAL_COPY_VALUE(retval, *var_ptr);
    zendi_zval_copy_ctor(*retval);
    
    SEPARATE_ZVAL_IF_NOT_REF(var_ptr);
    if (UNEXPECTED(Z_TYPE_PP(var_ptr) == IS_OBJECT)
    && Z_OBJ_HANDLER_PP(var_ptr, get)
       && Z_OBJ_HANDLER_PP(var_ptr, set)) {
        /* proxy object */
        zval *val = Z_OBJ_HANDLER_PP(var_ptr, get)(*var_ptr TSRMLS_CC);
        Z_ADDREF_P(val);
        fast_increment_function(val);
        Z_OBJ_HANDLER_PP(var_ptr, set)(var_ptr, val TSRMLS_CC);
        zval_ptr_dtor(&val);
    } else {
        fast_increment_function(*var_ptr);
    }
    
    CHECK_EXCEPTION();
    ZEND_VM_NEXT_OPCODE();
｝ 
```

从上面可以看出，后缀自增与前缀自增在底层实现的大部分是类似的，但是不同的点在于，后缀自增多了一个临时变量，用于存储原始的变量的值，但是它并没有前缀自增的RETURN_VALUE_USED操作。 

> 简言之，后缀自增使用的是存放在临时变量中的值，即变量的原始值，而最终变量本身的值还是会增加。


### 一些奇怪的php自增和自减


```
$a = '2D9';	$a++;	//string 2E0
$a = '2E0';	$a++;	//float 3
$a = '010';	$a++;	//11
$a = 010;	$a++;	//9
```


第一个很好理解。<br>
对于第二个，并不是我们想的 '2E1'，而是3。注意输出结果为 float 3，原来这里 `$`a='2E0',对`$`a执行递增，由于字符串`$`a中包含'E'，所以会被当作float来取值。科学计数法 2E0 表示 2*10^0 值为2，对其加1则结果为3。<br> 
对于第三个，`$`a='010'，对`$`a执行递增，字符串`$`a会被当作integer来处理，即为10，对其加1则结果为11。<br>
对于第四个，`$`a=010，对`$`a执行递增，`$`a本来就是数字类型，由于是0开头，表示8进制，即为8，对其加1则结果为9。<br>




# Happy coding.