package prp_7936;

import java.io.Serializable;
import java.util.List;

public class huffFile7936 implements Serializable {

	private static final long serialVersionUID = 1L;

	List<huffNode7936> huff;
	String encodedString;

	public List<huffNode7936> getHuff() {
		return huff;
	}

	public void setHuff(List<huffNode7936> huff) {
		this.huff = huff;
	}

	public String getEncodedString() {
		return encodedString;
	}

	public void setEncodedString(String encodedString) {
		this.encodedString = encodedString;
	}

}

