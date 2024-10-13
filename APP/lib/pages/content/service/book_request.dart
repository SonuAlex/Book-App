class BookRequest {
  final String title;
  final String userId;
  final String ownerId;
  final int response;

  BookRequest({
    required this.title,
    required this.userId,
    required this.ownerId,
    required this.response,
  });

  factory BookRequest.fromJson(Map<String, dynamic> json) {
    return BookRequest(
      title: json['title'],
      userId: json['user_id'],
      ownerId: json['owner_id'],
      response: json['response'],
    );
  }
}

class RequestData {
  final List<BookRequest> incoming;
  final List<BookRequest> outgoing;

  RequestData({
    required this.incoming,
    required this.outgoing,
  });

  factory RequestData.fromJson(Map<String, dynamic> json) {
    List<BookRequest> parseRequests(List<dynamic> requests) {
      return requests.map((request) => BookRequest.fromJson(request)).toList();
    }

    return RequestData(
      incoming: parseRequests(json['incoming']),
      outgoing: parseRequests(json['outgoing']),
    );
  }
}
