# c++ string类 常用API
## string对象的声明和定义
**首先我们在使用string类应该导入string包**
`#include <string>`

```
void func1{
    string s1 = "hello world";//调用=的重载操作符，给s1对象赋值
    string s2("hello");//调用构造函数初始化对象s2
    string s3 = s2;
    string s4(s2);
    string s5(3,'a'); //等价于string s5("aaa")
}
```
## string查找和替换
查找有find和rfind方法，find方法主要是从前往后开始查找，而rfind方法主要是从后往前开始查找

替换有replace方法

**具体的查找方法如下：**
```
//返回值都是对用的查找到的字符串的下标如果没有找到，返回-1
int find(const string& str, int pos=0) const;//查找str第一次出现的位置，从pos开始查找
int find(const char* s, int pos=0) const;//查找s第一次出现的位置，从pos开始查找
int find(const char* s, int pos, int n) const;//取字符串s的前n个字符然后在调用方法的字符串中从下标为pos处开始查找
int find(const char c, int pos = 0) const;// 查找字符c第一次出现的位置，
int rfind(const string& str, int pos = npos) const;//从下标pos处开始反向查找字符串str，pos指的是这个字符串的最后一个位置的下标
int rfind(const char* s, int pos=npos) const;//从pos位置反向查找字符串s
int rfind(const char* s, int pos, int n) const;//从pos位置反向查找字符串s的前n个字符出现的位置
int rfind(const char c, int pos = npos) const;//反向查找字符c
```
**具体的替换方法如下：**
```
string& replace(int pos, int n, const string& str);//替换从pos开始的n个字符为str
string& replace(int pos, int n, const char* s);//替换从pos开始的n个字符为字符串s
```
还有一些另外的查找函数，比如：
>find_first_of,find_last_of,find_first_not_of,find_last_not_of

>可以深入的学一下这些用法[https://www.cnblogs.com/zpcdbky/p/4471454.html]

## string的比较
compare方法在>时返回1，<时返回-1，==时返回0，具体的比较细节和c语言是一样的，不清楚可以百度下
```
int compare(const string& s) const;
int compare(const char* s) const;
```
## string截取子串(也叫做字符串的切割)
`string substr(int pos=0, int n = npos) const;//返回由pos开始的n个字符组成的字符串`
## string插入和删除
```
string& insert(int ops, const char* s);//在pos下标对应的字符前插入字符串s
string& insert(int ops, const string& str);//在pos下标对应的字符前插入字符串str
string& insert(int pos, int n, int char c); //在指定位置前插入n个字符c
```

`string& erase(int pos, int n=npos);//删除从pos开始的n个字符`

## string类常用的函数也就是以上列出来的，string类中还有很多成员函数，具体可以参考c++文档