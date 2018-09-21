// KRISHNA MURALI cs610 7936 prp
package prp_7936;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import prp_7936.huffFile7936;

public class hdec7936 {

	public static List<Byte> byteArr = new ArrayList<>();

	public static void main(String[] args) {

		String fileName = "C:\\Users\\krish\\Desktop\\video.mp4.huf";
		decompress7936(fileName);

	}

	public static void decompress7936(String fileName) {

		try {
			File f = new File(fileName);
			FileInputStream fis = new FileInputStream(f);
			ObjectInputStream ois = new ObjectInputStream(fis);
			huffFile7936 huffmanFile = (huffFile7936) ois.readObject();
			List<huffNode7936> pq = huffmanFile.getHuff();
			String encoding = huffmanFile.getEncodedString();
			char[] encode = encoding.toCharArray();
			ois.close();
			fis.close();
			f.delete();
			getFileContents7936(pq.get(0), encode, 0, encode.length, pq.get(0));
			writeToFile7936(byteArr, fileName);

		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (ClassNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

	public static void writeToFile7936(List<Byte> byteArr, String fileName) {
		try {

			String outputFile = fileName.substring(0, fileName.lastIndexOf("."));
			byte[] reader = new byte[byteArr.size()];
			Path path = Paths.get(outputFile);

			for (int i = 0; i < byteArr.size(); i++) {
				reader[i] = byteArr.get(i);
			}

			Files.write(path, reader);
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

	public static List<Byte> getFileContents7936(huffNode7936 pq, char[] encode, int flag, int size, huffNode7936 root) {
		int pos = 0;
		huffNode7936 current = new huffNode7936();
		current = root;

		while (pos < encode.length) {
			char c = encode[pos];
			if (c == '0' && current.getLeftChild() != null) {
				current = current.getLeftChild();
			} else if (c == '1' && current.getRightChild() != null) {
				current = current.getRightChild();
			}
			if (current.getLeftChild() == null && current.getRightChild() == null) {
				byteArr.add(current.fileChar);
				current = root;
			}
			pos++;
		}

		return byteArr;

	}
}
