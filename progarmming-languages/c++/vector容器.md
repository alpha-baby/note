# vector容器
## vector容器的初始化
```
#include <iostream>
#include <vector>

int main()
{
	int arr[] = { 10, 20 ,30, 40 };
	std::vector<int> v1(arr, arr+sizeof(arr)/sizeof(int));
	std::vector<int> v3(v1.begin(), v1.end());//其本质和前一个原理一样的都是传一个指针进去
	std::vector<int> v2(v1);

	for (std::vector<int>::iterator it = v1.begin(); it != v1.end(); it++) {
		std::cout << (*it) << std::endl;
	}
	return 0;
}
```
## vector的常用赋值操作
```
#include <iostream>
#include <vector>

int main()
{
	int arr[] = { 10, 20 ,30, 40 };
	std::vector<int> v1(arr, arr+sizeof(arr)/sizeof(int));
	
	for (std::vector<int>::iterator it = v1.begin(); it != v1.end(); it++) { //遍历打印vector里的值
		std::cout << (*it) << std::endl;
	}
	std::vector<int> v2;
	v2.assign(v1.begin(), v1.end());//把v1复制给v2，assign是分配的意思
	v2 = v1; //效果一样
	for (std::vector<int>::iterator it = v2.begin(); it != v2.end(); it++) {
		std::cout << (*it) << std::endl;
	}
	return 0;
}
```
```
int main()
{
	int arr[] = { 10, 20 ,30, 40 };
	std::vector<int> v1(arr, arr+sizeof(arr)/sizeof(int));
	
	int arr2[] = { 40, 30 ,20, 10 };
	std::vector<int> v2(arr2, arr2+sizeof(arr2)/sizeof(int));
	v1.swap(v2);//交换两个容器，其实内部的原理是交换了容器内的指针
	for (std::vector<int>::iterator it = v1.begin(); it != v1.end(); it++) { //遍历打印vector里的值
		std::cout << (*it) << std::endl;
	}
	return 0;
}
```
## vector的大小操作
**返回容器中元素的个数**
`size(); `
**判断容器是否为空**
`empty(); `
**_重新制定容器的长度为num，若容器变长，则以默认值填充新位置。如果容器变短则末尾超出容器长度的元素被删除。_**
`resize(int num)`
**_重新制定容器的长度为num，若容器变长，则以elem填充新位置。如果容器变短则末尾超出容器长度的元素被删除_。**
`resize(int num, elem)`
**如果你预先知道了容器需要的容量大小，可以重新定制容器的预留空间大小**
`reserve()`
**返回容器的容量**
`capacity()`
**容器预留len个元素长度，预留位置不初始化，元素不可访问, 返回的值比size()更大**
`reserve(int len)`
## vector存取数据
```
#include <iostream>
#include <vector>

int main()
{
	int arr[] = { 10, 20 ,30, 40 };
	std::vector<int> v1(arr, arr+sizeof(arr)/sizeof(int));
	v1[1] = 12;
	v1.at(2) = 13;
	for (int i = 0; i < v1.size(); i++) {
		std::cout << v1[i] << " ";
	}
	std::cout << std::endl;
	return 0;
}
```
其中at() 和 []的区别在于如果越界at会抛出out_of_range的异常，而[]则不会抛出异常
**返回容器中的第一个元素**
`front()`
**返回容器中的最后一个元素**
`back()`
## vector插入和删除操作
**迭代器指向位置pos插入count个元素ele**
`insert(const_iterator pos, int count, ele)`
**尾部插入元素ele**
`push_back(ele)`
**删除最后一个元素**
`pop_back()`
**删除迭代器从start到end之间的元素**
`erase(const_iterator start, const_iterator end)`
**删除迭代器指向的元素，**
`erase(const_iterator pos)`
**删除容器中所有元素**
`clear() `

### vector空间收缩
在插入数据时，如果容器的容量不够则会重新申请分配空间，但是如果容器的容量大很，我们执行resize后并不会减小，钥怎样收缩空间呢？请看下代码：
```
#include <iostream>
#include <vector>
inline void showSize(std::vector<int> &v1) {
	std::cout << "seize:" << v1.size() << std::endl;
	std::cout << "capacity:" << v1.capacity() << std::endl;
}
int main()
{
	int arr[] = { 10, 20 ,30, 40 };
	std::vector<int> v1;
	v1.resize(1000);
	showSize(v1);
	v1.resize(10);
	showSize(v1);
	std::vector<int>(v1).swap(v1);
	showSize(v1);
	return 0;
}
```