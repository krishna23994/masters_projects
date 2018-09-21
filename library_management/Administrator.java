package dmsd_project;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;
import java.util.Map;

public class Administrator {

	public static String addDocCopy(String docId, String copyNo, String position, String libId) {
		Connection conn = null;
		try {

			conn = DatabaseConnection.getConnection();
			Statement st = conn.createStatement();
			String sql = "select * from COPY WHERE DOCID='" + docId + "' AND COPYNO='" + copyNo + "' AND LIBID='" + libId + "' ";
			ResultSet rs = st.executeQuery(sql);
			List<Map<Object, Object>> result = DatabaseConnection.resultSetToArrayList(rs);
			if (result.size() == 0) {
				sql = "insert into COPY (DOCID,COPYNO,POSITION,LIBID)VALUES('" + docId + "','" + copyNo + "','"
						+ position + "','" + libId + "')";
				st.executeUpdate(sql);
				st.close();
				return StringConstants.SUCCESS;
			} else {
				return StringConstants.FAILURE;
			}
		} catch (SQLException e) {
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

	public static String checkCopyStatus(String copyId) {

		return copyId;

	}

	public static String addReader(String readerId, String rname, String rtype, String raddress) {
		Connection conn = null;
		try {

			conn = DatabaseConnection.getConnection();
			Statement st = conn.createStatement();
			String sql = "select * from READER WHERE READERID='" + readerId + "'";
			ResultSet rs = st.executeQuery(sql);
			List<Map<Object, Object>> result = DatabaseConnection.resultSetToArrayList(rs);
			if (result.size() == 0) {
				sql = "insert into READER (READERID,RTYPE,RNAME,ADDRESS)VALUES('" + readerId + "','" + rtype + "','"
						+ rname + "','" + raddress + "')";
				st.executeUpdate(sql);
				st.close();
				return StringConstants.SUCCESS;
			} else {
				return StringConstants.FAILURE;
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

		return StringConstants.ERROR;
	}

	public static List<Map<Object, Object>> getBranchInfo() {

		Connection conn = null;
		List<Map<Object, Object>> result = null;
		try {

			conn = DatabaseConnection.getConnection();
			Statement st = conn.createStatement();
			String sql = "select LIBID AS LibId,LNAME as LibName,LLOCATION as LibLocation from BRANCH";
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

	public static List<Map<Object, Object>> getTopBorrowers(String libId)

	{
		Connection conn = null;
		List<Map<Object, Object>> result = null;
		try {

			conn = DatabaseConnection.getConnection();
			Statement st = conn.createStatement();
			String sql = "select COUNT(*) as cnt,R.RNAME as title from BORROWS B,READER R WHERE B.READERID=R.READERID and B.LIBID="
					+ libId + " GROUP BY B.READERID ORDER BY CNT DESC LIMIT 10";
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

	public static List<Map<Object, Object>> getTopBooks(String libId)

	{
		Connection conn = null;
		List<Map<Object, Object>> result = null;
		try {

			conn = DatabaseConnection.getConnection();
			Statement st = conn.createStatement();
			String sql = "select COUNT(*) AS CNT,D.TITLE as TITLE from BORROWS B,DOCUMENT D WHERE B.DOCID=D.DOCID and B.LIBID='"
					+ libId + "' GROUP BY B.DOCID ORDER BY CNT DESC LIMIT 10";
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

	public static List<Map<Object, Object>> getTopBooksofYear(String year)

	{
		Connection conn = null;
		List<Map<Object, Object>> result = null;
		try {

			conn = DatabaseConnection.getConnection();
			Statement st = conn.createStatement();
			String sql = "select COUNT(*) AS CNT,D.TITLE as TITLE from BORROWS B,DOCUMENT D WHERE B.DOCID=D.DOCID and YEAR(B.BDTIME)='"
					+ year + "' GROUP BY B.DOCID ORDER BY CNT DESC LIMIT 10";
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

	public static List<Map<Object, Object>> getAvgPaidFine()

	{
		Connection conn = null;
		List<Map<Object, Object>> result = null;
		try {
			
			conn = DatabaseConnection.getConnection();
			Statement st = conn.createStatement();
			String sql = "SELECT CAST(AVG(DATEDIFF(B.RBDATE,B.BDTIME)*0.2) AS CHAR) as AVG_FINE,B.READERID as RID,R.RNAME AS RNAME FROM BORROWS B,READER R WHERE B.READERID=R.READERID AND DATEDIFF(B.RBDATE,B.BDTIME)>20 AND B.RBDATE IS NOT NULL GROUP BY B.READERID";
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

	public static List<Map<Object, Object>> getCopyStatus(String copyNo,String docId,String libId)

	{
		Connection conn = null;
		List<Map<Object, Object>> result = null;
		try {

			conn = DatabaseConnection.getConnection();
			Statement st = conn.createStatement();
			String sql = "SELECT 'BORROW' AS status FROM COPY WHERE COPY.COPYNO IN(SELECT COPYNO FROM BORROWS WHERE RBDATE IS NULL) AND COPY.COPYNO ='"
					+ copyNo + "' AND COPY.DOCID ='"
					+ docId + "' AND COPY.LIBID ='"
					+ libId + "'";
			ResultSet rs = st.executeQuery(sql);
			result = DatabaseConnection.resultSetToArrayList(rs);
			if (result.size() == 0) {
				sql = "SELECT 'RESERVE' AS status FROM COPY WHERE COPY.COPYNO IN(SELECT COPYNO FROM RESERVES) AND COPY.COPYNO ='"
					+ copyNo + "' AND COPY.DOCID ='"
					+ docId + "' AND COPY.LIBID ='"
					+ libId + "'";
				rs = st.executeQuery(sql);
				result = DatabaseConnection.resultSetToArrayList(rs);
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

		return result;

	}

	public static String adminLogin(String username, String password) {
		Connection conn = null;
		List<Map<Object, Object>> result = null;
		try {
			conn = DatabaseConnection.getConnection();
			Statement st = conn.createStatement();
			String sql = "SELECT * FROM ADMINLOGIN WHERE USERNAME='" + username + "' AND PASSWORD='" + password + "'";
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
