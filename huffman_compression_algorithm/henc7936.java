// KRISHNA MURALI cs610 7936 prp
package prp_7936;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

class MaxHeapHuffman<huffNode7936 extends Comparable<huffNode7936>> implements Serializable {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	private List<huffNode7936> huffNodes = new ArrayList<>();

	public void insert(huffNode7936 hn) {
		huffNodes.add(hn);
		maxHeapify();

	}

	public List<huffNode7936> maxHeap() {
		return huffNodes;
	}

	public int size() {
		return huffNodes.size();
	}

	public void maxHeapify() {
		int idx = huffNodes.size() - 1;

		while (idx > 0) {
			int parentIdx = (idx - 1) / 2;
			huffNode7936 child = huffNodes.get(idx);
			huffNode7936 parent = huffNodes.get(parentIdx);

			if (child.compareTo(parent) > 0) {
				huffNodes.set(parentIdx, child);
				huffNodes.set(idx, parent);
				idx = parentIdx;

			} else {
				break;
			}

		}

	}

	public huffNode7936 removeMax() {
		huffNode7936 huffNode = null;
		if (huffNodes.size() != 0) {
			if (huffNodes.size() == 1) {
				return huffNodes.remove(0);
			}

			huffNode = huffNodes.get(0);
			huffNodes.set(0, huffNodes.remove(huffNodes.size() - 1));
			downHeapify();

		}

		return huffNode;

	}

	public huffNode7936 peepHeap() {
		return huffNodes.get(0);

	}

	public void downHeapify() {
		int rootIdx = 0;
		int leftIdx = 1;
		int size = huffNodes.size();
		while (leftIdx < size) {

			int maxIdx = leftIdx;
			int rightIdx = leftIdx + 1;
			if (rightIdx < size) {
				huffNode7936 left = huffNodes.get(leftIdx);
				huffNode7936 right = huffNodes.get(rightIdx);
				if (right.compareTo(left) > 0) {
					maxIdx = rightIdx;
				}
			}

			huffNode7936 parentNode = huffNodes.get(rootIdx);
			huffNode7936 childNode = huffNodes.get(maxIdx);

			if (parentNode.compareTo(childNode) < 0) {
				huffNodes.set(rootIdx, childNode);
				huffNodes.set(maxIdx, parentNode);

				rootIdx = maxIdx;
				leftIdx = 2 * rootIdx + 1;
			} else {
				break;
			}

		}

	}

}





public class henc7936 {

	public static StringBuilder encodeString = new StringBuilder();
	public static List<Byte> byteArr = new ArrayList<>();
	public static Map<Byte, String> encodedMap = new HashMap<>();
	public static Map<Byte, Integer> occurences = new HashMap<>();

	public static void main(String[] args) {
		String fileName ="C:\\Users\\krish\\Desktop\\video.mp4";
		compress7936(fileName);

	}

	public static void compress7936(String fileName) {
		huffFile7936 huffmanFile = new huffFile7936();
		try {
			MaxHeapHuffman<huffNode7936> pq = new MaxHeapHuffman<>();
			List<Byte> ir = new ArrayList<Byte>();
			Path filePath = Paths.get(fileName);
			byte[] fileData = Files.readAllBytes(filePath);

			for (int i = 0; i < fileData.length; i++) {
				byte b = fileData[i];
				ir.add(b);
				if (occurences.containsKey(b)) {
					int d = occurences.get(b);
					occurences.put(b, ++d);
				} else {
					occurences.put(b, 1);
				}
			}

			for (byte c : occurences.keySet()) {
				huffNode7936 node = new huffNode7936();
				node.setFileChar(c);
				node.setFreq(occurences.get(c));
				node.setLeftChild(null);
				node.setRightChild(null);
				pq.insert(node);

			}
			Files.delete(filePath);
			huffmanFile = createHuffmanTree7936(pq, ir);
			writetoCompressedFile7936(fileName, huffmanFile);

		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

	public static void writetoCompressedFile7936(String fileName, huffFile7936 huffmanFile) {
		try {
			File f = new File(fileName + ".huf");
			f.createNewFile();
			FileOutputStream fos = new FileOutputStream(f);
			ByteArrayOutputStream bis = new ByteArrayOutputStream();
			ObjectOutputStream oos = new ObjectOutputStream(bis);
			oos.writeObject(huffmanFile);
			oos.flush();
			oos.close();
			fos.write(bis.toByteArray());
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

	public static huffFile7936 createHuffmanTree7936(MaxHeapHuffman<huffNode7936> pq, List<Byte> ir) throws IOException {

		huffNode7936 root = null;
		huffFile7936 huffmanFile = new huffFile7936();
		while (pq.size() > 1) {

			huffNode7936 mergeNode = new huffNode7936();
			huffNode7936 min1 = pq.removeMax();
			huffNode7936 min2 = pq.removeMax();
			mergeNode.setFreq(min1.getFreq() + min2.getFreq());
			mergeNode.setLeftChild(min1);
			mergeNode.setRightChild(min2);
			mergeNode.setFileChar((byte) '#');
			root = mergeNode;
			pq.insert(mergeNode);
		}

		getEncodedString7936(root, "");
		encodeString.append(getCompleteEncodedString7936(encodedMap, ir));
		huffmanFile.setHuff(pq.maxHeap());
		huffmanFile.setEncodedString(encodeString.toString());
		return huffmanFile;

	}

	public static String getCompleteEncodedString7936(Map<Byte, String> encodedMap, List<Byte> arr) {

		StringBuffer finalString = new StringBuffer();
		for (int i = 0; i < arr.size(); i++) {

			finalString.append(encodedMap.get(arr.get(i)));

		}

		return finalString.toString();

	}

	public static void getEncodedString7936(huffNode7936 root, String s) {

		if (root.isLeaf())
			encodedMap.put(root.getFileChar(), s);
		else {
			getEncodedString7936(root.getLeftChild(), s + "0");
			getEncodedString7936(root.getRightChild(), s + "1");
		}

	}

}
