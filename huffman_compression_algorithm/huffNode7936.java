package prp_7936;

import java.io.Serializable;

public class huffNode7936 implements Comparable<huffNode7936>, Serializable {
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	int freq;
	byte fileChar;
	huffNode7936 leftChild;
	huffNode7936 rightChild;

	public int getFreq() {
		return freq;
	}

	public void setFreq(int freq) {
		this.freq = freq;
	}

	public byte getFileChar() {
		return fileChar;
	}

	public void setFileChar(byte fileChar) {
		this.fileChar = fileChar;
	}

	public huffNode7936 getLeftChild() {
		return leftChild;
	}

	public void setLeftChild(huffNode7936 leftChild) {
		this.leftChild = leftChild;
	}

	public huffNode7936 getRightChild() {
		return rightChild;
	}

	public void setRightChild(huffNode7936 rightChild) {
		this.rightChild = rightChild;
	}

	public boolean isLeaf() {
		return this.leftChild == null && this.rightChild == null;
	}

	@Override
	public int compareTo(huffNode7936 o) {
		return this.getFreq() - o.getFreq();
	}

}
