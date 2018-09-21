package dmsd_project;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Map;

public class Reader {

	public static List<Map<Object, Object>> getDocumentsList(String docId, String docTitle, String pubName) {
		String sql;
		Connection conn = null;
		List<Map<Object, Object>> result = null;
		try {

			conn = DatabaseConnection.getConnection();
			Statement st = conn.createStatement();
			if (docId.equals("") && docTitle.equals("") && pubName.equals("")) {
				sql = "SELECT D.DOCID AS docId,D.TITLE as docTitle,P.PUBNAME as pubName FROM DOCUMENT D,PUBLISHER P,COPY C WHERE D.PUBLISHERID = P.PUBLISHERID AND D.DOCID=C.DOCID IN(SELECT DOCID FROM COPY WHERE AVAILABLE='y')";
			} else {
				if (docId.equals("")) {
					if (docTitle.equals("")) {
						sql = "SELECT D.DOCID AS docId,D.TITLE as docTitle,P.PUBNAME as pubName FROM DOCUMENT D,PUBLISHER P WHERE D.PUBLISHERID = P.PUBLISHERID AND P.PUBNAME LIKE '%"
								+ pubName + "%' AND D.DOCID IN(SELECT DOCID FROM COPY WHERE AVAILABLE='y')";
					} else {
						sql = "SELECT D.DOCID AS docId,D.TITLE as docTitle,P.PUBNAME as pubName FROM DOCUMENT D,PUBLISHER P WHERE D.PUBLISHERID = P.PUBLISHERID AND D.TITLE LIKE '%"
								+ docTitle + "%' AND D.DOCID IN(SELECT DOCID FROM COPY WHERE AVAILABLE='y')";
					}

				} else if(docId.equals("reserve")){
					
					sql="SELECT D.DOCID AS docId,D.TITLE as docTitle,P.PUBNAME as pubName,C.COPYNO as copyNo,C.LIBID as libId FROM DOCUMENT D,PUBLISHER P,COPY C WHERE D.PUBLISHERID = P.PUBLISHERID AND D.DOCID=C.DOCID AND C.AVAILABLE='y'";
				}
				else{
					sql = "SELECT D.DOCID AS docId,D.TITLE as docTitle,P.PUBNAME as pubName FROM DOCUMENT D,PUBLISHER P WHERE D.PUBLISHERID = P.PUBLISHERID AND D.DOCID='"
							+ docId + "' AND D.DOCID IN(SELECT DOCID FROM COPY WHERE AVAILABLE='y')";
				}
			}
			ResultSet rs = st.executeQuery(sql);
			result = DatabaseConnection.resultSetToArrayList(rs);
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} finally {
			try {
				conn.close();
			} catch (SQLException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}

		return result;

	}

	public static String reserveDocument(String copyId, String docId, String libId, String readerId) {
		Connection conn = null;
		try {

			conn = DatabaseConnection.getConnection();
			Statement st = conn.createStatement();
			String sql = "UPDATE COPY SET AVAILABLE='n' WHERE COPYNO='" + copyId + "' AND DOCID='" + docId
					+ "' AND LIBID='" + libId + "' ";
			int update = st.executeUpdate(sql);
			if (update != 0) {
				sql = "INSERT INTO RESERVES VALUES (NULL,now(),'" + readerId + "','y','" + docId + "','" + copyId + "','"
						+ libId + "')";
				st.executeUpdate(sql);
				st.close();
				return StringConstants.SUCCESS;
			}

		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} finally {
			try {
				conn.close();
			} catch (SQLException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}

		return StringConstants.FAILURE;

	}

	public static String borrowDocument(String reserveId, String readerId, String docId, String copyId, String libId) {

		Connection conn = null;
		try {

			conn = DatabaseConnection.getConnection();
			Statement st = conn.createStatement();
			String sql = "DELETE FROM RESERVES WHERE RESNUMBER='" + reserveId + "'";
			int update = st.executeUpdate(sql);
			if (update != 0) {
				sql = "INSERT INTO BORROWS (BDTIME,READERID,DOCID,COPYNO,LIBID) VALUES (now(),'" + readerId + "','"
						+ docId + "','" + copyId + "','" + libId + "')";
				st.executeUpdate(sql);
				st.close();
				return StringConstants.SUCCESS;
			}

		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} finally {
			try {
				conn.close();
			} catch (SQLException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}

		return StringConstants.FAILURE;

	}

	public static String returnDocument(String readerId, String docId, String copyId, String libId,String borNo) {
		Connection conn = null;
		try {

			conn = DatabaseConnection.getConnection();
			Statement st = conn.createStatement();

			String sql = "UPDATE BORROWS SET RBDATE=now() WHERE READERID='" + readerId + "' AND COPYNO='" + copyId
					+ "' AND DOCID='" + docId + "' AND LIBID='" + libId + "' AND BORNUMBER='"+borNo+"'";
			int update = st.executeUpdate(sql);
			if (update != 0) {
				sql = "UPDATE COPY SET AVAILABLE='y' WHERE COPYNO='" + copyId + "' AND DOCID='" + docId
						+ "' AND LIBID='" + libId + "' ";
				update = st.executeUpdate(sql);
				if (update != 0) {
					return StringConstants.SUCCESS;
				}
			}
			st.close();

		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} finally {
			try {
				conn.close();
			} catch (SQLException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}

		return StringConstants.FAILURE;

	}
	
	public static List<Map<Object, Object>> getBorrowDocuments(String readerId) {
		Connection conn = null;
		List<Map<Object, Object>> result = null;
		try {

			conn = DatabaseConnection.getConnection();
			Statement st = conn.createStatement();

			String sql = "SELECT BORNUMBER AS borNo,LIBID as libId,DOCID as docId,COPYNO as copyNo FROM BORROWS WHERE READERID='"+readerId+"' AND RBDATE IS NULL";
			ResultSet rs = st.executeQuery(sql);
			result = DatabaseConnection.resultSetToArrayList(rs);
			st.close();

		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} finally {
			try {
				conn.close();
			} catch (SQLException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}

		return result;

	}

	public static List<Map<Object, Object>> computeFine(String readerId, String docId, String copyId, String libId,String borNo) {
		Connection conn = null;
		List<Map<Object, Object>> result = null;
		try {
			conn = DatabaseConnection.getConnection();
			Statement st = conn.createStatement();
			String sql = "SELECT CAST((DATEDIFF(now(), B.BDTIME) * 0.2) AS CHAR) FROM BORROWS B WHERE B.READERID='" + readerId
					+ "' AND B.DOCID='" + docId + "' AND B.COPYNO='" + copyId + "' AND B.LIBID='" + libId + "' AND B.BORNUMBER='"+borNo+"'";
			System.out.println(sql);
			ResultSet rs = st.executeQuery(sql);
			result = DatabaseConnection.resultSetToArrayList(rs);

		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			try {
				conn.close();
			} catch (SQLException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
		return result;

	}

	public static List<Map<Object, Object>> getReservedDocuments(String readerId) {
		Connection conn = null;
		List<Map<Object, Object>> result = null;
		try {
			conn = DatabaseConnection.getConnection();
			Statement st = conn.createStatement();
			String sql = "SELECT D.DOCID AS docId,D.TITLE AS docTitle,R.RESNUMBER AS resNo,R.COPYNO AS copyNo,R.LIBID AS libId FROM DOCUMENT D,RESERVES R WHERE D.DOCID=R.DOCID AND R.READERID='"
					+ readerId + "'";
			ResultSet rs = st.executeQuery(sql);
			result = DatabaseConnection.resultSetToArrayList(rs);

		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			try {
				conn.close();
			} catch (SQLException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
		return result;
	}

	public static List<Map<Object, Object>> getPubDetails() {
		Connection conn = null;
		List<Map<Object, Object>> result = null;
		try {
			conn = DatabaseConnection.getConnection();
			Statement st = conn.createStatement();
			String sql = "SELECT D.DOCID,D.TITLE,P.PUBNAME FROM DOCUMENT D,PUBLISHER P WHERE P.PUBLISHERID=D.PUBLISHERID";
			ResultSet rs = st.executeQuery(sql);
			result = DatabaseConnection.resultSetToArrayList(rs);

		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			try {
				conn.close();
			} catch (SQLException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
		return result;
	}

	public static String readerLogin(String readerId) {
		Connection conn = null;
		List<Map<Object, Object>> result = null;
		try {
			conn = DatabaseConnection.getConnection();
			Statement st = conn.createStatement();
			String sql = "SELECT * FROM READER WHERE READERID='" + readerId + "'";
			ResultSet rs = st.executeQuery(sql);
			result = DatabaseConnection.resultSetToArrayList(rs);
			if (result.size() > 0) {
				return StringConstants.SUCCESS;
			} else {
				return StringConstants.FAILURE;
			}

		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			try {
				conn.close();
			} catch (SQLException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
		return StringConstants.ERROR;
	}
}
