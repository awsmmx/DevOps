#
# If the descendingOrder flag is not set, then the selection goes as usual, if it is, then the selection goes the other way around 
#
def BinarySearch_Rec(array, descendingOrder, key, left, right):
    mid = left + (right - left) // 2

    if (left >= right):
        return -(1 + left)

    if (array[left] == key):
        return left

    if (array[mid] == key):
        if (mid == left + 1):
            return mid
        else:
            return BinarySearch_Rec(array, descendingOrder, key, left, mid + 1)

    elif (array[mid] > key) ^ descendingOrder:
        return BinarySearch_Rec(array, descendingOrder, key, left, mid)
    else:
        return BinarySearch_Rec(array, descendingOrder, key, mid + 1, right)

def BinarySearch_Rec_Wrapper(array, key):

    if array.Length == 0:
        return -1

    descendingOrder = array[0] > array[array.Length - 1]
    return BinarySearch_Rec(array, descendingOrder, key, 0, array.Length)


mylist = [2, 4, 7, 10, 11, 20, 25, 60, 88, 25215, 9999999]

x1 = BinarySearch_Rec(mylist, False, 7, 0, len(mylist))
x2 = BinarySearch_Rec(mylist, True, 7, 0, len(mylist))

print(x1, x2)